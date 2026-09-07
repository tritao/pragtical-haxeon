#include "pragtical_hx/platform.h"

#include <assert.h>
#include <stdio.h>

int main(void) {
  assert(phx_platform_abi_version() == PHX_PLATFORM_ABI_VERSION);
  assert(phx_platform_init(true));
  phx_handle first = phx_window_create("test", 800, 600);
  assert(first != 0 && phx_window_valid(first));
  phx_handle font = phx_font_create(first, "ignored-headlessly.ttf", 15);
  assert(font != 0);
  assert(phx_font_height(font) == 15);
  assert(phx_font_text_width(font, "hello") > 0);
  assert(phx_frame_begin(first));
  assert(phx_draw_rect(first, 0, 0, 10, 10, 0xffffffff));
  assert(phx_draw_text(first, font, 2, 2, "hello", 0xffffffff));
  assert(phx_frame_present(first));
  assert(phx_frame_count(first) == 1);

  phx_event resize = {
    .kind = PHX_EVENT_WINDOW_RESIZED,
    .window = first,
    .a = 1024,
    .b = 768
  };
  phx_event result = {0};
  assert(phx_event_push_for_test(&resize));
  assert(phx_event_poll(&result));
  assert(result.kind == PHX_EVENT_WINDOW_RESIZED);
  assert(result.window == first && result.a == 1024 && result.b == 768);

  assert(phx_font_destroy(font));
  assert(phx_window_destroy(first));
  assert(!phx_window_valid(first));
  phx_handle second = phx_window_create("replacement", 1, 1);
  assert(second != 0 && second != first);
  assert(!phx_window_valid(first));
  assert(!phx_window_destroy(first));
  assert(phx_window_destroy(second));
  phx_platform_shutdown();
  puts("PASS: platform ABI, event queue, frames, and stale handles");
  return 0;
}
