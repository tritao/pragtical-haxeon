#ifndef PRAGTICAL_HX_PLATFORM_SDL_H
#define PRAGTICAL_HX_PLATFORM_SDL_H

#include <stdbool.h>
#include <SDL3/SDL.h>

/* Internal adapter used by the native shell. SDL types never cross the public
   platform ABI or enter Haxeon code. */
bool phx_event_push_sdl(const SDL_Event *event);

#endif
