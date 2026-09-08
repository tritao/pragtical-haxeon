#include "pragtical_hx/platform.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef PHX_WITH_SDL
#include <SDL3/SDL.h>
#include "platform_sdl.h"
#include "renderer/cache.h"
#include "renderer/renderer.h"
#include "renderer/window.h"
#endif

#define PHX_INDEX_BITS 8
#define PHX_INDEX_MASK ((1 << PHX_INDEX_BITS) - 1)

typedef struct phx_window_slot {
  uint32_t generation;
  bool occupied;
  int32_t width;
  int32_t height;
  int32_t frames;
  char title[128];
#ifdef PHX_WITH_SDL
  SDL_Window *window;
  RenWindow *renderer;
#endif
} phx_window_slot;

typedef struct phx_font_slot {
  uint32_t generation;
  bool occupied;
  int32_t height;
  int32_t advance;
#ifdef PHX_WITH_SDL
  RenFont *font;
#endif
} phx_font_slot;

static bool initialized;
static bool is_headless;
static phx_window_slot windows[PHX_MAX_WINDOWS];
static phx_font_slot fonts[PHX_MAX_FONTS];
static phx_event events[PHX_EVENT_CAPACITY];
static uint32_t event_read;
static uint32_t event_count;
static char last_error[256];
static char *clipboard_text;

#ifdef PHX_WITH_SDL
static int32_t normalize_key(SDL_Keycode key) {
  switch (key) {
    case SDLK_BACKSPACE: return PHX_KEY_BACKSPACE;
    case SDLK_TAB: return PHX_KEY_TAB;
    case SDLK_RETURN: return PHX_KEY_ENTER;
    case SDLK_ESCAPE: return PHX_KEY_ESCAPE;
    case SDLK_DELETE: return PHX_KEY_DELETE;
    case SDLK_LEFT: return PHX_KEY_LEFT;
    case SDLK_RIGHT: return PHX_KEY_RIGHT;
    case SDLK_UP: return PHX_KEY_UP;
    case SDLK_DOWN: return PHX_KEY_DOWN;
    case SDLK_HOME: return PHX_KEY_HOME;
    case SDLK_END: return PHX_KEY_END;
    case SDLK_A: return PHX_KEY_A;
    case SDLK_S: return PHX_KEY_S;
    case SDLK_Y: return PHX_KEY_Y;
    case SDLK_Z: return PHX_KEY_Z;
    case SDLK_W: return PHX_KEY_W;
    case SDLK_P: return PHX_KEY_P;
    case SDLK_F: return PHX_KEY_F;
    case SDLK_H: return PHX_KEY_H;
    case SDLK_C: return PHX_KEY_C;
    case SDLK_V: return PHX_KEY_V;
    case SDLK_X: return PHX_KEY_X;
    case SDLK_PAGEUP: return PHX_KEY_PAGE_UP;
    case SDLK_PAGEDOWN: return PHX_KEY_PAGE_DOWN;
    case SDLK_K: return PHX_KEY_K;
    case SDLK_J: return PHX_KEY_J;
    case SDLK_SLASH: return PHX_KEY_SLASH;
    case SDLK_D: return PHX_KEY_D;
    case SDLK_G: return PHX_KEY_G;
    case SDLK_B: return PHX_KEY_B;
    case SDLK_SPACE: return PHX_KEY_SPACE;
    default: return PHX_KEY_UNKNOWN;
  }
}

static int32_t normalize_modifiers(SDL_Keymod modifiers) {
  int32_t result = 0;
  if (modifiers & SDL_KMOD_SHIFT) result |= PHX_MOD_SHIFT;
  if (modifiers & SDL_KMOD_CTRL) result |= PHX_MOD_CTRL;
  if (modifiers & SDL_KMOD_ALT) result |= PHX_MOD_ALT;
  return result;
}
#endif

static bool fail(const char *message) {
  snprintf(last_error, sizeof(last_error), "%s", message);
  return false;
}

static bool store_clipboard(const char *text) {
  const char *value = text ? text : "";
  size_t size = strlen(value) + 1;
  char *replacement = (char *)realloc(clipboard_text, size);
  if (!replacement) return fail("could not allocate clipboard text");
  memcpy(replacement, value, size);
  clipboard_text = replacement;
  return true;
}

static phx_handle make_handle(uint32_t index, uint32_t generation) {
  return (phx_handle)((generation << PHX_INDEX_BITS) | (index + 1));
}

static phx_window_slot *resolve_window(phx_handle handle) {
  if (handle <= 0) return NULL;
  uint32_t encoded_index = (uint32_t)handle & PHX_INDEX_MASK;
  uint32_t generation = (uint32_t)handle >> PHX_INDEX_BITS;
  if (encoded_index == 0 || encoded_index > PHX_MAX_WINDOWS) return NULL;
  phx_window_slot *slot = &windows[encoded_index - 1];
  if (!slot->occupied || slot->generation != generation) return NULL;
  return slot;
}

#ifdef PHX_WITH_SDL
static phx_handle window_handle_from_id(SDL_WindowID id) {
  for (uint32_t index = 0; index < PHX_MAX_WINDOWS; index++) {
    if (windows[index].occupied && windows[index].window &&
        SDL_GetWindowID(windows[index].window) == id)
      return make_handle(index, windows[index].generation);
  }
  return 0;
}
#endif

static phx_font_slot *resolve_font(phx_handle handle) {
  if (handle <= 0) return NULL;
  uint32_t encoded_index = (uint32_t)handle & PHX_INDEX_MASK;
  uint32_t generation = (uint32_t)handle >> PHX_INDEX_BITS;
  if (encoded_index == 0 || encoded_index > PHX_MAX_FONTS) return NULL;
  phx_font_slot *slot = &fonts[encoded_index - 1];
  if (!slot->occupied || slot->generation != generation) return NULL;
  return slot;
}

#ifdef PHX_WITH_SDL
static RenColor renderer_color(int32_t rgba) {
  return (RenColor){.r = (rgba >> 24) & 255, .g = (rgba >> 16) & 255,
                    .b = (rgba >> 8) & 255, .a = rgba & 255};
}
#endif

int32_t phx_platform_abi_version(void) { return PHX_PLATFORM_ABI_VERSION; }

bool phx_platform_init(bool headless) {
  if (initialized) return fail("platform is already initialized");
#ifndef PHX_WITH_SDL
  if (!headless) return fail("graphical backend is not compiled in");
#else
  if (!headless) {
    if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS)) return fail(SDL_GetError());
    if (ren_init() != 0) { SDL_Quit(); return fail(SDL_GetError()); }
  }
#endif
  memset(windows, 0, sizeof(windows));
  memset(fonts, 0, sizeof(fonts));
  memset(events, 0, sizeof(events));
  event_read = 0;
  event_count = 0;
  last_error[0] = '\0';
  initialized = true;
  is_headless = headless;
  if (!store_clipboard("")) {
    initialized = false;
    return false;
  }
  return true;
}

void phx_platform_shutdown(void) {
  if (!initialized) return;
#ifdef PHX_WITH_SDL
  if (!is_headless) {
    for (uint32_t index = 0; index < PHX_MAX_FONTS; index++) {
      if (fonts[index].font) ren_font_free(fonts[index].font);
    }
    for (uint32_t index = 0; index < PHX_MAX_WINDOWS; index++) {
      if (windows[index].renderer) ren_destroy(windows[index].renderer);
      else if (windows[index].window) SDL_DestroyWindow(windows[index].window);
    }
    ren_free();
    SDL_Quit();
  }
#endif
  initialized = false;
  memset(windows, 0, sizeof(windows));
  memset(fonts, 0, sizeof(fonts));
  event_read = 0;
  event_count = 0;
  free(clipboard_text);
  clipboard_text = NULL;
}

const char *phx_platform_last_error(void) { return last_error; }

phx_handle phx_window_create(const char *title, int32_t width, int32_t height) {
  if (!initialized) {
    fail("platform is not initialized");
    return 0;
  }
  if (width <= 0 || height <= 0) {
    fail("window dimensions must be positive");
    return 0;
  }
  for (uint32_t index = 0; index < PHX_MAX_WINDOWS; index++) {
    phx_window_slot *slot = &windows[index];
    if (slot->occupied) continue;
    slot->generation++;
    if (slot->generation == 0) slot->generation = 1;
    slot->occupied = true;
    slot->width = width;
    slot->height = height;
    slot->frames = 0;
    snprintf(slot->title, sizeof(slot->title), "%s", title ? title : "");
#ifdef PHX_WITH_SDL
    if (!is_headless) {
      slot->window = SDL_CreateWindow(slot->title, width, height, SDL_WINDOW_RESIZABLE);
      if (!slot->window) {
        slot->occupied = false;
        fail(SDL_GetError());
        return 0;
      }
      slot->renderer = ren_create(slot->window);
      if (!slot->renderer) {
        SDL_DestroyWindow(slot->window);
        slot->window = NULL;
        slot->occupied = false;
        fail(SDL_GetError());
        return 0;
      }
      if (!SDL_StartTextInput(slot->window)) {
        ren_destroy(slot->renderer);
        slot->renderer = NULL;
        slot->window = NULL;
        slot->occupied = false;
        fail(SDL_GetError());
        return 0;
      }
    }
#endif
    return make_handle(index, slot->generation);
  }
  fail("window table is full");
  return 0;
}

bool phx_window_destroy(phx_handle handle) {
  phx_window_slot *slot = resolve_window(handle);
  if (!slot) return fail("invalid or stale window handle");
#ifdef PHX_WITH_SDL
  if (slot->window) SDL_StopTextInput(slot->window);
  if (slot->renderer) ren_destroy(slot->renderer);
  else if (slot->window) SDL_DestroyWindow(slot->window);
  slot->renderer = NULL;
  slot->window = NULL;
#endif
  slot->occupied = false;
  return true;
}

bool phx_window_valid(phx_handle handle) { return resolve_window(handle) != NULL; }

int32_t phx_window_width(phx_handle handle) {
  phx_window_slot *slot = resolve_window(handle);
  if (!slot) { fail("invalid or stale window handle"); return -1; }
  return slot->width;
}

int32_t phx_window_height(phx_handle handle) {
  phx_window_slot *slot = resolve_window(handle);
  if (!slot) { fail("invalid or stale window handle"); return -1; }
  return slot->height;
}

int32_t phx_window_display_scale_milli(phx_handle handle) {
  phx_window_slot *slot = resolve_window(handle);
  if (!slot) { fail("invalid or stale window handle"); return -1; }
#ifdef PHX_WITH_SDL
  if (!is_headless) return (int32_t)(SDL_GetWindowDisplayScale(slot->window) * 1000.0f + 0.5f);
#endif
  return 1000;
}

bool phx_event_poll(phx_event *event) {
  if (!event) return false;
  if (event_count > 0) {
    *event = events[event_read];
    event_read = (event_read + 1) % PHX_EVENT_CAPACITY;
    event_count--;
    return true;
  }
  /* The graphical executable feeds this queue from SDL_AppEvent. */
  return false;
}

#ifdef PHX_WITH_SDL
bool phx_event_push_sdl(const SDL_Event *input) {
  if (!initialized || is_headless || !input) return false;
  phx_event event;
  memset(&event, 0, sizeof(event));
  switch (input->type) {
        case SDL_EVENT_QUIT: event.kind = PHX_EVENT_QUIT; break;
        case SDL_EVENT_WINDOW_RESIZED:
          event.kind = PHX_EVENT_WINDOW_RESIZED;
          event.a = input->window.data1;
          event.b = input->window.data2;
          for (uint32_t index = 0; index < PHX_MAX_WINDOWS; index++) {
            if (windows[index].occupied && windows[index].window &&
                SDL_GetWindowID(windows[index].window) == input->window.windowID) {
              windows[index].width = event.a;
              windows[index].height = event.b;
              event.window = make_handle(index, windows[index].generation);
              ren_resize_window(windows[index].renderer);
              break;
            }
          }
          break;
        case SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED:
          event.kind = PHX_EVENT_DISPLAY_SCALE_CHANGED;
          event.window = window_handle_from_id(input->window.windowID);
          for (uint32_t index = 0; index < PHX_MAX_WINDOWS; index++) {
            if (windows[index].occupied && windows[index].window &&
                SDL_GetWindowID(windows[index].window) == input->window.windowID) {
              ren_resize_window(windows[index].renderer);
              event.a = phx_window_display_scale_milli(
                make_handle(index, windows[index].generation));
              break;
            }
          }
          break;
        case SDL_EVENT_KEY_DOWN:
          event.kind = PHX_EVENT_KEY_DOWN;
          event.window = window_handle_from_id(input->key.windowID);
          event.a = normalize_key(input->key.key);
          event.b = normalize_modifiers(input->key.mod);
          break;
        case SDL_EVENT_KEY_UP:
          event.kind = PHX_EVENT_KEY_UP;
          event.window = window_handle_from_id(input->key.windowID);
          event.a = normalize_key(input->key.key);
          event.b = normalize_modifiers(input->key.mod);
          break;
        case SDL_EVENT_TEXT_INPUT:
          event.kind = PHX_EVENT_TEXT_INPUT;
          event.window = window_handle_from_id(input->text.windowID);
          snprintf(event.text, sizeof(event.text), "%s", input->text.text);
          break;
        case SDL_EVENT_MOUSE_MOTION:
          event.kind = PHX_EVENT_MOUSE_MOVED;
          event.window = window_handle_from_id(input->motion.windowID);
          event.a = (int32_t)input->motion.x;
          event.b = (int32_t)input->motion.y;
          event.c = (int32_t)input->motion.xrel;
          event.d = (int32_t)input->motion.yrel;
          break;
        case SDL_EVENT_MOUSE_BUTTON_DOWN:
        case SDL_EVENT_MOUSE_BUTTON_UP:
          event.kind = input->type == SDL_EVENT_MOUSE_BUTTON_DOWN
            ? PHX_EVENT_MOUSE_BUTTON_DOWN : PHX_EVENT_MOUSE_BUTTON_UP;
          event.window = window_handle_from_id(input->button.windowID);
          event.a = input->button.button;
          event.b = (int32_t)input->button.x;
          event.c = (int32_t)input->button.y;
          event.d = input->button.clicks;
          break;
        case SDL_EVENT_MOUSE_WHEEL:
          event.kind = PHX_EVENT_MOUSE_WHEEL;
          event.window = window_handle_from_id(input->wheel.windowID);
          event.a = (int32_t)(input->wheel.y * 100.0f);
          event.b = (int32_t)(-input->wheel.x * 100.0f);
          break;
        default: return false;
  }
  return phx_event_push_for_test(&event);
}
#endif

bool phx_event_push_for_test(const phx_event *event) {
  if (!initialized) return fail("platform is not initialized");
  if (!event) return fail("event is null");
  if (event_count == PHX_EVENT_CAPACITY) return fail("event queue is full");
  uint32_t write = (event_read + event_count) % PHX_EVENT_CAPACITY;
  events[write] = *event;
  event_count++;
  return true;
}

bool phx_clipboard_set(const char *text) {
  if (!initialized) return fail("platform is not initialized");
#ifdef PHX_WITH_SDL
  if (!is_headless && !SDL_SetClipboardText(text ? text : ""))
    return fail(SDL_GetError());
#endif
  return store_clipboard(text);
}

const char *phx_clipboard_get(void) {
  if (!initialized) {
    fail("platform is not initialized");
    return NULL;
  }
#ifdef PHX_WITH_SDL
  if (!is_headless) {
    char *text = SDL_GetClipboardText();
    if (!text) {
      fail(SDL_GetError());
      return NULL;
    }
    bool stored = store_clipboard(text);
    SDL_free(text);
    if (!stored) return NULL;
  }
#endif
  return clipboard_text ? clipboard_text : "";
}

bool phx_frame_begin(phx_handle window) {
  phx_window_slot *slot = resolve_window(window);
  if (!slot) return fail("invalid or stale window handle");
#ifdef PHX_WITH_SDL
  if (!is_headless) {
    rencache_begin_frame(&slot->renderer->cache);
  }
#endif
  return true;
}

bool phx_set_clip_rect(phx_handle window, int32_t x, int32_t y, int32_t width,
                       int32_t height) {
  phx_window_slot *slot = resolve_window(window);
  if (!slot) return fail("invalid or stale window handle");
  if (width < 0 || height < 0) return fail("clip dimensions are negative");
#ifdef PHX_WITH_SDL
  if (!is_headless)
    rencache_set_clip_rect(&slot->renderer->cache, (RenRect){x, y, width, height});
#else
  (void)x; (void)y;
#endif
  return true;
}

bool phx_draw_rect(phx_handle window, int32_t x, int32_t y, int32_t width,
                   int32_t height, int32_t rgba) {
  phx_window_slot *slot = resolve_window(window);
  if (!slot) return fail("invalid or stale window handle");
  if (width < 0 || height < 0) return fail("rectangle dimensions are negative");
#ifdef PHX_WITH_SDL
  if (!is_headless) {
    rencache_draw_rect(&slot->renderer->cache,
                       (RenRect){x, y, width, height}, renderer_color(rgba), true);
  }
#else
  (void)x; (void)y; (void)rgba;
#endif
  return true;
}

phx_handle phx_font_create(phx_handle window, const char *path, int32_t size) {
  if (!resolve_window(window)) { fail("invalid or stale window handle"); return 0; }
  if (size <= 0) { fail("font size must be positive"); return 0; }
#ifndef PHX_WITH_SDL
  (void)path;
#endif
  for (uint32_t index = 0; index < PHX_MAX_FONTS; index++) {
    phx_font_slot *slot = &fonts[index];
    if (slot->occupied) continue;
    slot->generation++;
    if (slot->generation == 0) slot->generation = 1;
    slot->occupied = true;
    slot->height = size;
    slot->advance = (size * 3 + 2) / 5;
#ifdef PHX_WITH_SDL
    if (!is_headless) {
      slot->font = ren_font_load(path, (float)size, FONT_ANTIALIASING_GRAYSCALE,
                                 FONT_HINTING_SLIGHT, 0, true);
      if (!slot->font) { slot->occupied = false; fail(SDL_GetError()); return 0; }
      RenFont *group[] = {slot->font, NULL};
      slot->height = ren_font_group_get_height(group);
      slot->advance = (int)ren_font_group_get_width(group, "M", 1, (RenTab){0}, NULL);
    }
#endif
    return make_handle(index, slot->generation);
  }
  fail("font table is full");
  return 0;
}

bool phx_font_destroy(phx_handle font) {
  phx_font_slot *slot = resolve_font(font);
  if (!slot) return fail("invalid or stale font handle");
#ifdef PHX_WITH_SDL
  if (slot->font) ren_font_free(slot->font);
  slot->font = NULL;
#endif
  slot->occupied = false;
  return true;
}

int32_t phx_font_height(phx_handle font) {
  phx_font_slot *slot = resolve_font(font);
  if (!slot) { fail("invalid or stale font handle"); return -1; }
  return slot->height;
}

int32_t phx_font_text_width(phx_handle font, const char *text) {
  phx_font_slot *slot = resolve_font(font);
  if (!slot) { fail("invalid or stale font handle"); return -1; }
#ifdef PHX_WITH_SDL
  if (!is_headless) {
    RenFont *group[] = {slot->font, NULL};
    return (int)ren_font_group_get_width(group, text ? text : "",
      text ? strlen(text) : 0, (RenTab){0}, NULL);
  }
#endif
  return (int32_t)strlen(text ? text : "") * slot->advance;
}

bool phx_draw_text(phx_handle window, phx_handle font, int32_t x, int32_t y,
                   const char *text, int32_t rgba) {
  phx_window_slot *slot = resolve_window(window);
  if (!slot) return fail("invalid or stale window handle");
  phx_font_slot *font_slot = resolve_font(font);
  if (!font_slot) return fail("invalid or stale font handle");
#ifdef PHX_WITH_SDL
  if (!is_headless) {
    RenFont *group[] = {font_slot->font, NULL};
    rencache_draw_text(&slot->renderer->cache, group, text ? text : "",
      text ? strlen(text) : 0, x, y, renderer_color(rgba), (RenTab){0});
  }
#else
  (void)x; (void)y; (void)text; (void)rgba;
#endif
  return true;
}

bool phx_frame_present(phx_handle window) {
  phx_window_slot *slot = resolve_window(window);
  if (!slot) return fail("invalid or stale window handle");
#ifdef PHX_WITH_SDL
  if (!is_headless) rencache_end_frame(&slot->renderer->cache);
#endif
  slot->frames++;
  return true;
}

int32_t phx_frame_count(phx_handle window) {
  phx_window_slot *slot = resolve_window(window);
  if (!slot) {
    fail("invalid or stale window handle");
    return -1;
  }
  return slot->frames;
}
