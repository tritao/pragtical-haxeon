#ifndef PRAGTICAL_HX_HOST_H
#define PRAGTICAL_HX_HOST_H

#include <stdbool.h>

bool phx_haxeon_callbacks_ready(void);
bool phx_haxeon_event(void);
bool phx_haxeon_iterate(bool *keep_running);
bool phx_haxeon_quit(void);

#endif
