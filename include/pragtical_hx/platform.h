#ifndef PRAGTICAL_HX_PLATFORM_H
#define PRAGTICAL_HX_PLATFORM_H

#include <stdbool.h>
#include <stdint.h>
#include "pragtical_hx/platform_abi.h"

#define PHX_MAX_WINDOWS 64
#define PHX_MAX_FONTS 32
#define PHX_MAX_PROCESSES 32
#define PHX_MAX_PROCESS_ARGS 256
#define PHX_MAX_PROCESS_ENV 128
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

phx_handle phx_process_create(const char *executable, const char *cwd);
bool phx_process_add_argument(phx_handle process, const char *argument);
bool phx_process_set_environment(phx_handle process, const char *key,
                                 const char *value);
bool phx_process_start(phx_handle process);
/* Writes at most the descriptor's atomic pipe limit. Returns the full accepted
   byte count, zero when the nonblocking pipe would block, and -1 on error. */
int32_t phx_process_write(phx_handle process, const char *data, int32_t length);
bool phx_process_close_stdin(phx_handle process);
int32_t phx_process_read(phx_handle process, bool standard_error,
                         char *buffer, int32_t capacity);
/* 1 while running, 2 after exit, and 0 for an invalid/stale handle. */
int32_t phx_process_state(phx_handle process);
int32_t phx_process_exit_status(phx_handle process);
bool phx_process_cancel(phx_handle process);
bool phx_process_destroy(phx_handle process);

#endif
