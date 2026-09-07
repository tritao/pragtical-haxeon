package app;

import platform.Native;
import platform.Platform;
import core.Application;
import renderer.Renderer;

class GraphicalMain {
	static function main():Int {
		if (Native.abi_version() != Platform.ABI_VERSION)
			throw "platform ABI version mismatch";
		Platform.require(Native.init(false), "initialize graphical platform");
		var arguments = Sys.args(), path = arguments.length == 0 ? "README.md" : arguments[0];
		var window = Native.window_create("Pragtical Haxeon", 960, 640), running = true;
		Platform.require(window != 0, "create editor window");
		var renderer = new Renderer(window, "data/fonts/JetBrainsMono-Regular.ttf", 15);
		var application = new Application(renderer, Native.window_width(window), Native.window_height(window));
		for (argument in arguments)
			application.open(argument);
		if (arguments.length == 0)
			application.open(path);
		while (running) {
			while (Native.event_poll()) {
				var kind = Native.event_kind();
				if (kind == Platform.EVENT_QUIT)
					running = false;
				else if (kind == Platform.EVENT_TEXT_INPUT) {
					application.root.textInput(Native.event_text());
				}
				else if (kind == Platform.EVENT_WINDOW_RESIZED)
					application.root.resize(Native.event_a(), Native.event_b());
				else if (kind == Platform.EVENT_MOUSE_WHEEL)
					application.root.wheel(Native.event_a(), Native.event_b());
				else if (kind == Platform.EVENT_MOUSE_BUTTON_DOWN)
					application.root.mouseDown(Native.event_a(), Native.event_b(), Native.event_c());
				else if (kind == Platform.EVENT_MOUSE_BUTTON_UP)
					application.root.mouseUp(Native.event_a());
				else if (kind == Platform.EVENT_MOUSE_MOVED)
					application.root.mouseMove(Native.event_a(), Native.event_b());
				else if (kind == Platform.EVENT_KEY_DOWN) {
					application.keyPressed(Native.event_a(), Native.event_b());
				}
			}
			renderer.begin();
			application.root.draw();
			renderer.present();
		}
		renderer.destroy();
		Platform.require(Native.window_destroy(window), "destroy editor window");
		Native.shutdown();
		return 0;
	}
}
