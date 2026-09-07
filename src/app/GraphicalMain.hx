package app;

import platform.Native;
import platform.Platform;
import editor.Document;
import editor.EditorView;
import renderer.Renderer;
import command.CommandRegistry;
import command.EditorCommands;
import command.Keymap;

class GraphicalMain {
	static function main():Int {
		if (Native.abi_version() != Platform.ABI_VERSION)
			throw "platform ABI version mismatch";
		Platform.require(Native.init(false), "initialize graphical platform");
		var arguments = Sys.args(), path = arguments.length == 0 ? "README.md" : arguments[0], document = Document.open(path);
		var window = Native.window_create("Pragtical Haxeon", 960, 640), running = true;
		Platform.require(window != 0, "create editor window");
		var renderer = new Renderer(window, "data/fonts/JetBrainsMono-Regular.ttf", 15);
		var view = new EditorView(document, renderer, Native.window_width(window), Native.window_height(window));
		var commands = new CommandRegistry(), keymap = new Keymap(commands);
		EditorCommands.install(commands, keymap, document, view);
		while (running) {
			while (Native.event_poll()) {
				var kind = Native.event_kind();
				if (kind == Platform.EVENT_QUIT)
					running = false;
				else if (kind == Platform.EVENT_TEXT_INPUT) {
					document.insert(Native.event_text());
					view.cursorChanged();
				}
				else if (kind == Platform.EVENT_WINDOW_RESIZED)
					view.resize(Native.event_a(), Native.event_b());
				else if (kind == Platform.EVENT_MOUSE_WHEEL)
					view.wheel(Native.event_a(), Native.event_b());
				else if (kind == Platform.EVENT_MOUSE_BUTTON_DOWN)
					view.mouseDown(Native.event_a(), Native.event_b(), Native.event_c());
				else if (kind == Platform.EVENT_MOUSE_BUTTON_UP)
					view.mouseUp(Native.event_a());
				else if (kind == Platform.EVENT_MOUSE_MOVED)
					view.mouseMove(Native.event_a(), Native.event_b());
				else if (kind == Platform.EVENT_KEY_DOWN) {
					if (keymap.onKeyPressed(Native.event_a(), Native.event_b()))
						view.cursorChanged();
				}
			}
			renderer.begin();
			view.draw(path);
			renderer.present();
		}
		renderer.destroy();
		Platform.require(Native.window_destroy(window), "destroy editor window");
		Native.shutdown();
		return 0;
	}
}
