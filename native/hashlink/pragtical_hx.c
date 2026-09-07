#define HL_NAME(n) pragtical_hx_##n
#include <hl.h>

#include "pragtical_hx/platform.h"

static phx_event current_event;

HL_PRIM int HL_NAME(abi_version)(void) { return phx_platform_abi_version(); }
HL_PRIM bool HL_NAME(init)(bool headless) { return phx_platform_init(headless); }
HL_PRIM void HL_NAME(shutdown)(void) { phx_platform_shutdown(); }
HL_PRIM vbyte *HL_NAME(last_error)(void) {
  return (vbyte *)phx_platform_last_error();
}
HL_PRIM int HL_NAME(window_create)(vbyte *title, int width, int height) {
  const char *utf8 = title ? hl_to_utf8((uchar *)title) : "";
  return phx_window_create(utf8, width, height);
}
HL_PRIM bool HL_NAME(window_destroy)(int window) {
  return phx_window_destroy(window);
}
HL_PRIM bool HL_NAME(window_valid)(int window) {
  return phx_window_valid(window);
}
HL_PRIM bool HL_NAME(event_poll)(void) { return phx_event_poll(&current_event); }
HL_PRIM int HL_NAME(event_kind)(void) { return current_event.kind; }
HL_PRIM int HL_NAME(event_window)(void) { return current_event.window; }
HL_PRIM int HL_NAME(event_a)(void) { return current_event.a; }
HL_PRIM int HL_NAME(event_b)(void) { return current_event.b; }
HL_PRIM vbyte *HL_NAME(event_text)(void) {
  int length = hl_utf8_length((vbyte *)current_event.text, 0);
  uchar *result = (uchar *)hl_alloc_bytes((length + 1) * (int)sizeof(uchar));
  hl_from_utf8(result, length, current_event.text);
  result[length] = 0;
  return (vbyte *)result;
}
HL_PRIM bool HL_NAME(event_push_test)(int kind, int window, int a, int b) {
  phx_event event = {.kind = kind, .window = window, .a = a, .b = b};
  return phx_event_push_for_test(&event);
}
HL_PRIM bool HL_NAME(frame_begin)(int window) { return phx_frame_begin(window); }
HL_PRIM bool HL_NAME(draw_rect)(int window, int x, int y, int width, int height,
                                int rgba) {
  return phx_draw_rect(window, x, y, width, height, rgba);
}
HL_PRIM int HL_NAME(font_create)(int window, vbyte *path, int size) {
  const char *utf8 = path ? hl_to_utf8((uchar *)path) : "";
  return phx_font_create(window, utf8, size);
}
HL_PRIM bool HL_NAME(font_destroy)(int font) { return phx_font_destroy(font); }
HL_PRIM int HL_NAME(font_height)(int font) { return phx_font_height(font); }
HL_PRIM int HL_NAME(font_text_width)(int font, vbyte *text) {
  const char *utf8 = text ? hl_to_utf8((uchar *)text) : "";
  return phx_font_text_width(font, utf8);
}
HL_PRIM bool HL_NAME(draw_text)(int window, int font, int x, int y, vbyte *text,
                                int rgba) {
  const char *utf8 = text ? hl_to_utf8((uchar *)text) : "";
  return phx_draw_text(window, font, x, y, utf8, rgba);
}
HL_PRIM bool HL_NAME(frame_present)(int window) {
  return phx_frame_present(window);
}
HL_PRIM int HL_NAME(frame_count)(int window) { return phx_frame_count(window); }

DEFINE_PRIM(_I32, abi_version, _NO_ARG);
DEFINE_PRIM(_BOOL, init, _BOOL);
DEFINE_PRIM(_VOID, shutdown, _NO_ARG);
DEFINE_PRIM(_BYTES, last_error, _NO_ARG);
DEFINE_PRIM(_I32, window_create, _BYTES _I32 _I32);
DEFINE_PRIM(_BOOL, window_destroy, _I32);
DEFINE_PRIM(_BOOL, window_valid, _I32);
DEFINE_PRIM(_BOOL, event_poll, _NO_ARG);
DEFINE_PRIM(_I32, event_kind, _NO_ARG);
DEFINE_PRIM(_I32, event_window, _NO_ARG);
DEFINE_PRIM(_I32, event_a, _NO_ARG);
DEFINE_PRIM(_I32, event_b, _NO_ARG);
DEFINE_PRIM(_BYTES, event_text, _NO_ARG);
DEFINE_PRIM(_BOOL, event_push_test, _I32 _I32 _I32 _I32);
DEFINE_PRIM(_BOOL, frame_begin, _I32);
DEFINE_PRIM(_BOOL, draw_rect, _I32 _I32 _I32 _I32 _I32 _I32);
DEFINE_PRIM(_I32, font_create, _I32 _BYTES _I32);
DEFINE_PRIM(_BOOL, font_destroy, _I32);
DEFINE_PRIM(_I32, font_height, _I32);
DEFINE_PRIM(_I32, font_text_width, _I32 _BYTES);
DEFINE_PRIM(_BOOL, draw_text, _I32 _I32 _I32 _I32 _BYTES _I32);
DEFINE_PRIM(_BOOL, frame_present, _I32);
DEFINE_PRIM(_I32, frame_count, _I32);
