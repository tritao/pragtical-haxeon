#include "renderer/backend.h"
#include "renderer/backend/surface.h"

/* Haxeon starts with Pragtical's portable surface renderer. Keeping selection
   here avoids pulling the GPU backends into the platform bridge prematurely. */
const RenBackend *renbackend_current(void) { return renbackend_surface(); }
const char *renbackend_default_name(void) { return "surface"; }
bool renbackend_select(const char *name) {
  return name != NULL && SDL_strcmp(name, "surface") == 0;
}
