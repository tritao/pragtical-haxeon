#define HL_NAME(n) pragtical_hx_##n
#include <hl.h>

#include "pragtical_hx/platform.h"
#include "pragtical_hx/host.h"

static phx_event current_event;
static vclosure *plugin_api_dispatch;
static vclosure *host_event;
static vclosure *host_iterate;
static vclosure *host_quit;

#define PROCESS_STREAM_SLOTS 32
typedef struct process_stream_state {
  int handle;
  unsigned char stdout_carry[4];
  int stdout_carry_length;
  unsigned char stderr_carry[4];
  int stderr_carry_length;
} process_stream_state;
static process_stream_state process_streams[PROCESS_STREAM_SLOTS];

static bool call_host(vclosure *callback, vdynamic **result) {
  bool raised = false;
  if (!callback) return false;
  *result = hl_dyn_call_safe(callback, NULL, 0, &raised);
  if (raised) {
    hl_print_uncaught_exception(*result);
    return false;
  }
  return true;
}

bool phx_haxeon_callbacks_ready(void) {
  return host_event && host_iterate && host_quit;
}

bool phx_haxeon_event(void) {
  vdynamic *result = NULL;
  return call_host(host_event, &result);
}

bool phx_haxeon_iterate(bool *keep_running) {
  vdynamic *result = NULL;
  if (!keep_running || !call_host(host_iterate, &result)) return false;
  *keep_running = result && result->v.i != 0;
  return true;
}

bool phx_haxeon_quit(void) {
  vdynamic *result = NULL;
  bool ok = !host_quit || call_host(host_quit, &result);
  host_event = NULL;
  host_iterate = NULL;
  host_quit = NULL;
  return ok;
}

static vbyte *utf8_string(const char *text) {
  const char *value = text ? text : "";
  int length = hl_utf8_length((vbyte *)value, 0);
  uchar *result = (uchar *)hl_alloc_bytes((length + 1) * (int)sizeof(uchar));
  hl_from_utf8(result, length, value);
  result[length] = 0;
  return (vbyte *)result;
}

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
HL_PRIM int HL_NAME(window_width)(int window) { return phx_window_width(window); }
HL_PRIM int HL_NAME(window_height)(int window) { return phx_window_height(window); }
HL_PRIM int HL_NAME(window_display_scale_milli)(int window) { return phx_window_display_scale_milli(window); }
HL_PRIM bool HL_NAME(text_input_area)(int window, int x, int y, int width,
                                      int height, int cursor) {
  return phx_text_input_area(window, x, y, width, height, cursor);
}
HL_PRIM bool HL_NAME(event_poll)(void) { return phx_event_poll(&current_event); }
HL_PRIM int HL_NAME(event_kind)(void) { return current_event.kind; }
HL_PRIM int HL_NAME(event_window)(void) { return current_event.window; }
HL_PRIM int HL_NAME(event_a)(void) { return current_event.a; }
HL_PRIM int HL_NAME(event_b)(void) { return current_event.b; }
HL_PRIM int HL_NAME(event_c)(void) { return current_event.c; }
HL_PRIM int HL_NAME(event_d)(void) { return current_event.d; }
HL_PRIM vbyte *HL_NAME(event_text)(void) {
	return utf8_string(current_event.text);
}
HL_PRIM bool HL_NAME(event_push_test)(int kind, int window, int a, int b) {
  phx_event event = {.kind = kind, .window = window, .a = a, .b = b};
  return phx_event_push_for_test(&event);
}
HL_PRIM bool HL_NAME(event_push_text_test)(int kind, int window, int a, int b,
                                           vbyte *text) {
  phx_event event = {.kind = kind, .window = window, .a = a, .b = b};
  const char *utf8 = text ? hl_to_utf8((uchar *)text) : "";
  snprintf(event.text, sizeof(event.text), "%s", utf8);
  return phx_event_push_for_test(&event);
}
HL_PRIM bool HL_NAME(clipboard_set)(vbyte *text) {
  const char *utf8 = text ? hl_to_utf8((uchar *)text) : "";
  return phx_clipboard_set(utf8);
}
HL_PRIM vbyte *HL_NAME(clipboard_get)(void) {
  return utf8_string(phx_clipboard_get());
}
HL_PRIM bool HL_NAME(frame_begin)(int window) { return phx_frame_begin(window); }
HL_PRIM bool HL_NAME(set_clip_rect)(int window, int x, int y, int width, int height) {
  return phx_set_clip_rect(window, x, y, width, height);
}
HL_PRIM bool HL_NAME(draw_rect)(int window, int x, int y, int width, int height,
                                int rgba) {
  return phx_draw_rect(window, x, y, width, height, rgba);
}
HL_PRIM int HL_NAME(font_create)(int window, vbyte *path, int size) {
  const char *utf8 = path ? hl_to_utf8((uchar *)path) : "";
  return phx_font_create(window, utf8, size);
}
HL_PRIM bool HL_NAME(font_add_fallback)(int font, vbyte *path) {
  const char *utf8 = path ? hl_to_utf8((uchar *)path) : "";
  return phx_font_add_fallback(font, utf8);
}
HL_PRIM int HL_NAME(font_fallback_count)(int font) {
  return phx_font_fallback_count(font);
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

HL_PRIM int HL_NAME(process_create)(vbyte *executable, vbyte *cwd) {
  int handle = phx_process_create(executable ? hl_to_utf8((uchar *)executable) : "",
    cwd ? hl_to_utf8((uchar *)cwd) : "");
  int index = (handle & 255) - 1;
  if (index >= 0 && index < PROCESS_STREAM_SLOTS) {
    memset(&process_streams[index], 0, sizeof(process_streams[index]));
    process_streams[index].handle = handle;
  }
  return handle;
}
HL_PRIM bool HL_NAME(process_add_argument)(int process, vbyte *argument) {
  return phx_process_add_argument(process,
    argument ? hl_to_utf8((uchar *)argument) : "");
}
HL_PRIM bool HL_NAME(process_set_environment)(int process, vbyte *key,
                                               vbyte *value) {
  return phx_process_set_environment(process,
    key ? hl_to_utf8((uchar *)key) : "", value ? hl_to_utf8((uchar *)value) : "");
}
HL_PRIM bool HL_NAME(process_start)(int process) {
  return phx_process_start(process);
}
HL_PRIM int HL_NAME(process_write)(int process, vbyte *data) {
  const char *utf8 = data ? hl_to_utf8((uchar *)data) : "";
  return phx_process_write(process, utf8, (int32_t)strlen(utf8));
}
HL_PRIM bool HL_NAME(process_close_stdin)(int process) {
  return phx_process_close_stdin(process);
}
static int complete_utf8_prefix(const unsigned char *data, int length) {
  int offset = 0;
  while (offset < length) {
    unsigned char lead = data[offset];
    int width = lead < 0x80 ? 1 : (lead & 0xE0) == 0xC0 ? 2
      : (lead & 0xF0) == 0xE0 ? 3 : (lead & 0xF8) == 0xF0 ? 4 : 1;
    if (offset + width > length) return offset;
    bool valid = true;
    for (int index = 1; index < width; index++)
      if ((data[offset + index] & 0xC0) != 0x80) valid = false;
    offset += valid ? width : 1;
  }
  return offset;
}

static vbyte *process_output(int process, bool standard_error) {
  unsigned char buffer[4100];
  int index = (process & 255) - 1;
  process_stream_state *state = index >= 0 && index < PROCESS_STREAM_SLOTS
    && process_streams[index].handle == process ? &process_streams[index] : NULL;
  int *carry_length = state ? (standard_error ? &state->stderr_carry_length
    : &state->stdout_carry_length) : NULL;
  unsigned char *carry = state ? (standard_error ? state->stderr_carry
    : state->stdout_carry) : NULL;
  int prefix = carry_length ? *carry_length : 0;
  if (prefix > 0) memcpy(buffer, carry, (size_t)prefix);
  int32_t count = phx_process_read(process, standard_error,
    (char *)buffer + prefix, 4096);
  if (count < 0) return utf8_string("");
  int total = prefix + count;
  int complete = complete_utf8_prefix(buffer, total);
  if (carry_length) {
    *carry_length = total - complete;
    if (*carry_length > 0) memcpy(carry, buffer + complete, (size_t)*carry_length);
  }
  if (complete == 0) return utf8_string("");
  buffer[complete] = '\0';
  return utf8_string((const char *)buffer);
}
HL_PRIM vbyte *HL_NAME(process_stdout)(int process) {
  return process_output(process, false);
}
HL_PRIM vbyte *HL_NAME(process_stderr)(int process) {
  return process_output(process, true);
}
HL_PRIM int HL_NAME(process_state)(int process) {
  return phx_process_state(process);
}
HL_PRIM int HL_NAME(process_exit_status)(int process) {
  return phx_process_exit_status(process);
}
HL_PRIM bool HL_NAME(process_cancel)(int process) {
  return phx_process_cancel(process);
}
HL_PRIM bool HL_NAME(process_destroy)(int process) {
  bool destroyed = phx_process_destroy(process);
  int index = (process & 255) - 1;
  if (destroyed && index >= 0 && index < PROCESS_STREAM_SLOTS
      && process_streams[index].handle == process)
    memset(&process_streams[index], 0, sizeof(process_streams[index]));
  return destroyed;
}

HL_PRIM void HL_NAME(plugin_api_install)(vclosure *dispatch) {
	if (plugin_api_dispatch == NULL) hl_add_root(&plugin_api_dispatch);
	plugin_api_dispatch = dispatch;
}

HL_PRIM void HL_NAME(host_install)(vclosure *event, vclosure *iterate,
                                   vclosure *quit) {
  if (host_event == NULL) {
    hl_add_root(&host_event);
    hl_add_root(&host_iterate);
    hl_add_root(&host_quit);
  }
  host_event = event;
  host_iterate = iterate;
  host_quit = quit;
}

HL_PRIM vbyte *HL_NAME(plugin_api_call)(int operation, vbyte *token, vbyte *a,
		vbyte *b, vbyte *c) {
	if (plugin_api_dispatch == NULL) hl_error("Pragtical plugin host is not installed");
	if (plugin_api_dispatch->hasValue)
		return ((vbyte *(*)(vdynamic *, int, vbyte *, vbyte *, vbyte *, vbyte *))plugin_api_dispatch->fun)(
			(vdynamic *)plugin_api_dispatch->value, operation, token, a, b, c);
	return ((vbyte *(*)(int, vbyte *, vbyte *, vbyte *, vbyte *))plugin_api_dispatch->fun)(operation, token, a, b, c);
}

#include "pragtical_hx/native_ffi.h"
