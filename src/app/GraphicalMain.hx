package app;

import platform.Native;
import platform.Platform;

class GraphicalMain {
	static function main():Int {
		if (Native.abi_version() != Platform.ABI_VERSION)
			throw "platform ABI version mismatch";
		Platform.require(Native.init(false), "initialize graphical platform");
		var window = Native.window_create("Pragtical Haxeon", 960, 640), running = true;
		Platform.require(window != 0, "create editor window");
		while (running) {
			while (Native.event_poll())
				if (Native.event_kind() == Platform.EVENT_QUIT)
					running = false;
			Platform.require(Native.frame_begin(window), "begin frame");
			Platform.require(Native.draw_rect(window, 0, 0, 960, 42, 0x252525ff), "draw title bar");
			Platform.require(Native.draw_rect(window, 0, 42, 220, 598, 0x202020ff), "draw sidebar");
			Platform.require(Native.draw_text(window, 18, 17, "PRAGTICAL HAXEON", 0xe6e6e6ff), "draw title");
			Platform.require(Native.draw_text(window, 18, 68, "EXPLORER", 0xaaaaaaff), "draw explorer");
			Platform.require(Native.draw_text(window, 244, 68, "A new editor core is alive.", 0xffffffff), "draw editor text");
			Platform.require(Native.frame_present(window), "present frame");
		}
		Platform.require(Native.window_destroy(window), "destroy editor window");
		Native.shutdown();
		return 0;
	}
}
