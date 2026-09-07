#ifndef PRAGTICAL_HX_PLATFORM_H
#define PRAGTICAL_HX_PLATFORM_H

#include <stdbool.h>
#include <stdint.h>

#define PHX_PLATFORM_ABI_VERSION 2
#define PHX_MAX_WINDOWS 64
#define PHX_MAX_FONTS 32
#define PHX_EVENT_CAPACITY 256

typedef int32_t phx_handle;

typedef enum phx_event_kind {
  PHX_EVENT_NONE = 0,
  PHX_EVENT_QUIT = 1,
  PHX_EVENT_WINDOW_RESIZED = 2,
  PHX_EVENT_KEY_DOWN = 3,
  PHX_EVENT_KEY_UP = 4,
  PHX_EVENT_TEXT_INPUT = 5,
  PHX_EVENT_MOUSE_MOVED = 6,
  PHX_EVENT_MOUSE_BUTTON_DOWN = 7,
  PHX_EVENT_MOUSE_BUTTON_UP = 8,
  PHX_EVENT_MOUSE_WHEEL = 9
} phx_event_kind;

typedef enum phx_key {
  PHX_KEY_UNKNOWN = 0,
  PHX_KEY_BACKSPACE = 1,
  PHX_KEY_TAB = 2,
  PHX_KEY_ENTER = 3,
  PHX_KEY_ESCAPE = 4,
  PHX_KEY_DELETE = 5,
  PHX_KEY_LEFT = 6,
  PHX_KEY_RIGHT = 7,
  PHX_KEY_UP = 8,
  PHX_KEY_DOWN = 9,
  PHX_KEY_HOME = 10,
  PHX_KEY_END = 11,
  PHX_KEY_A = 12,
  PHX_KEY_S = 13,
  PHX_KEY_Y = 14,
  PHX_KEY_Z = 15
} phx_key;

#define PHX_MOD_SHIFT 1
#define PHX_MOD_CTRL 2
#define PHX_MOD_ALT 4

typedef struct phx_event {
  int32_t kind;
  phx_handle window;
  int32_t a;
  int32_t b;
  int32_t c;
  int32_t d;
  char text[64];
} phx_event;

int32_t phx_platform_abi_version(void);
bool phx_platform_init(bool headless);
void phx_platform_shutdown(void);
const char *phx_platform_last_error(void);

phx_handle phx_window_create(const char *title, int32_t width, int32_t height);
bool phx_window_destroy(phx_handle handle);
bool phx_window_valid(phx_handle handle);
int32_t phx_window_width(phx_handle handle);
int32_t phx_window_height(phx_handle handle);

bool phx_event_poll(phx_event *event);
bool phx_event_push_for_test(const phx_event *event);

bool phx_frame_begin(phx_handle window);
bool phx_set_clip_rect(phx_handle window, int32_t x, int32_t y, int32_t width,
                       int32_t height);
bool phx_draw_rect(phx_handle window, int32_t x, int32_t y, int32_t width,
                   int32_t height, int32_t rgba);
phx_handle phx_font_create(phx_handle window, const char *path, int32_t size);
bool phx_font_destroy(phx_handle font);
int32_t phx_font_height(phx_handle font);
int32_t phx_font_text_width(phx_handle font, const char *text);
bool phx_draw_text(phx_handle window, phx_handle font, int32_t x, int32_t y,
                   const char *text, int32_t rgba);
bool phx_frame_present(phx_handle window);
int32_t phx_frame_count(phx_handle window);

#endif
