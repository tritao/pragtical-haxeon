#ifndef PRAGTICAL_HX_PLATFORM_H
#define PRAGTICAL_HX_PLATFORM_H

#include <stdbool.h>
#include <stdint.h>
#include "pragtical_hx/platform_abi.h"

#define PHX_MAX_WINDOWS 64
#define PHX_MAX_FONTS 32
#define PHX_EVENT_CAPACITY 256

typedef int32_t phx_handle;

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
/* Window sizes, pointer coordinates and renderer coordinates are logical
   points. The display scale only describes their backing-pixel density. */
int32_t phx_window_display_scale_milli(phx_handle handle);

bool phx_event_poll(phx_event *event);
bool phx_event_push_for_test(const phx_event *event);

bool phx_clipboard_set(const char *text);
const char *phx_clipboard_get(void);

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
