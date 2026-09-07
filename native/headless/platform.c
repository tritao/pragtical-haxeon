#include "pragtical_hx/platform.h"

#include <stdio.h>
#include <string.h>

#ifdef PHX_WITH_SDL
#include <SDL3/SDL.h>
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
  SDL_Renderer *renderer;
#endif
} phx_window_slot;

static bool initialized;
static bool is_headless;
static phx_window_slot windows[PHX_MAX_WINDOWS];
static phx_event events[PHX_EVENT_CAPACITY];
static uint32_t event_read;
static uint32_t event_count;
static char last_error[256];

static bool fail(const char *message) {
  snprintf(last_error, sizeof(last_error), "%s", message);
  return false;
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

int32_t phx_platform_abi_version(void) { return PHX_PLATFORM_ABI_VERSION; }

bool phx_platform_init(bool headless) {
  if (initialized) return fail("platform is already initialized");
#ifndef PHX_WITH_SDL
  if (!headless) return fail("graphical backend is not compiled in");
#else
  if (!headless && !SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS))
    return fail(SDL_GetError());
#endif
  memset(windows, 0, sizeof(windows));
  memset(events, 0, sizeof(events));
  event_read = 0;
  event_count = 0;
  last_error[0] = '\0';
  initialized = true;
  is_headless = headless;
  return true;
}

void phx_platform_shutdown(void) {
#ifdef PHX_WITH_SDL
  if (!is_headless) {
    for (uint32_t index = 0; index < PHX_MAX_WINDOWS; index++) {
      if (windows[index].renderer) SDL_DestroyRenderer(windows[index].renderer);
      if (windows[index].window) SDL_DestroyWindow(windows[index].window);
    }
    SDL_Quit();
  }
#endif
  initialized = false;
  memset(windows, 0, sizeof(windows));
  event_read = 0;
  event_count = 0;
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
      slot->renderer = SDL_CreateRenderer(slot->window, NULL);
      if (!slot->renderer) {
        SDL_DestroyWindow(slot->window);
        slot->window = NULL;
        slot->occupied = false;
        fail(SDL_GetError());
        return 0;
      }
      SDL_SetRenderVSync(slot->renderer, 1);
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
  if (slot->renderer) SDL_DestroyRenderer(slot->renderer);
  if (slot->window) SDL_DestroyWindow(slot->window);
  slot->renderer = NULL;
  slot->window = NULL;
#endif
  slot->occupied = false;
  return true;
}

bool phx_window_valid(phx_handle handle) { return resolve_window(handle) != NULL; }

bool phx_event_poll(phx_event *event) {
  if (!event) return false;
  if (event_count > 0) {
    *event = events[event_read];
    event_read = (event_read + 1) % PHX_EVENT_CAPACITY;
    event_count--;
    return true;
  }
#ifdef PHX_WITH_SDL
  if (!is_headless) {
    SDL_Event input;
    while (SDL_PollEvent(&input)) {
      memset(event, 0, sizeof(*event));
      switch (input.type) {
        case SDL_EVENT_QUIT: event->kind = PHX_EVENT_QUIT; return true;
        case SDL_EVENT_WINDOW_RESIZED:
          event->kind = PHX_EVENT_WINDOW_RESIZED;
          event->a = input.window.data1;
          event->b = input.window.data2;
          return true;
        case SDL_EVENT_KEY_DOWN:
          event->kind = PHX_EVENT_KEY_DOWN;
          event->a = (int32_t)input.key.key;
          event->b = (int32_t)input.key.mod;
          return true;
        case SDL_EVENT_KEY_UP:
          event->kind = PHX_EVENT_KEY_UP;
          event->a = (int32_t)input.key.key;
          event->b = (int32_t)input.key.mod;
          return true;
        default: break;
      }
    }
  }
#endif
  return false;
}

bool phx_event_push_for_test(const phx_event *event) {
  if (!initialized) return fail("platform is not initialized");
  if (!event) return fail("event is null");
  if (event_count == PHX_EVENT_CAPACITY) return fail("event queue is full");
  uint32_t write = (event_read + event_count) % PHX_EVENT_CAPACITY;
  events[write] = *event;
  event_count++;
  return true;
}

bool phx_frame_begin(phx_handle window) {
  phx_window_slot *slot = resolve_window(window);
  if (!slot) return fail("invalid or stale window handle");
#ifdef PHX_WITH_SDL
  if (!is_headless) {
    SDL_SetRenderDrawColor(slot->renderer, 24, 24, 24, 255);
    SDL_RenderClear(slot->renderer);
  }
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
    SDL_FRect rect = {(float)x, (float)y, (float)width, (float)height};
    SDL_SetRenderDrawColor(slot->renderer, (rgba >> 24) & 255, (rgba >> 16) & 255,
                           (rgba >> 8) & 255, rgba & 255);
    if (!SDL_RenderFillRect(slot->renderer, &rect)) return fail(SDL_GetError());
  }
#else
  (void)x; (void)y; (void)rgba;
#endif
  return true;
}

bool phx_draw_text(phx_handle window, int32_t x, int32_t y, const char *text,
                   int32_t rgba) {
  phx_window_slot *slot = resolve_window(window);
  if (!slot) return fail("invalid or stale window handle");
#ifdef PHX_WITH_SDL
  if (!is_headless) {
    SDL_SetRenderDrawColor(slot->renderer, (rgba >> 24) & 255, (rgba >> 16) & 255,
                           (rgba >> 8) & 255, rgba & 255);
    if (!SDL_RenderDebugText(slot->renderer, (float)x, (float)y, text ? text : ""))
      return fail(SDL_GetError());
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
  if (!is_headless && !SDL_RenderPresent(slot->renderer)) return fail(SDL_GetError());
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
