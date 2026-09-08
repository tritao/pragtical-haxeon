package app;

import platform.Native;
import platform.Platform;
import platform.PlatformEvent;

class Main {
	static function main():Int {
		Platform.startHeadless();
		var first = Native.window_create("Pragtical Haxeon", 960, 640);
		Platform.require(first != 0, "create window");
		var font = Native.font_create(first, "ignored-headlessly.ttf", 15);
		Platform.require(font != 0, "create font");
		Platform.require(Native.frame_begin(first), "begin frame");
		Platform.require(Native.draw_rect(first, 0, 0, 960, 640, 0x181818ff), "draw background");
		Platform.require(Native.draw_text(first, font, 24, 24, "Pragtical Haxeon", 0xffffffff), "draw title");
		Platform.require(Native.frame_present(first), "present frame");
		Platform.require(Native.frame_count(first) == 1, "count frame");

		Platform.require(Native.event_push_test(Platform.EVENT_WINDOW_RESIZED, first, 1200, 800), "queue resize");
		var resize = Platform.pollEvent();
		var decoded = switch resize {
			case WindowResize(window, width, height): window == first && width == 1200 && height == 800;
			default: false;
		};
		Platform.require(decoded, "decode typed resize event");

		Platform.require(Native.font_destroy(font), "destroy font");
		Platform.require(Native.window_destroy(first), "destroy window");
		Platform.require(!Native.window_valid(first), "reject destroyed handle");
		var second = Native.window_create("Replacement", 320, 200);
		Platform.require(second != 0 && second != first, "advance handle generation");
		Platform.require(!Native.window_valid(first), "reject stale generation");
		Platform.require(Native.window_destroy(second), "destroy replacement window");
		Native.shutdown();
		return 0;
	}
}
