package app;

import platform.Native;
import platform.Platform;
import editor.Document;
import editor.EditorView;
import renderer.Renderer;

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
					var key = Native.event_a(), modifiers = Native.event_b(), shift = (modifiers & Platform.MOD_SHIFT) != 0,
						control = (modifiers & Platform.MOD_CTRL) != 0;
					if (control && key == Platform.KEY_S)
						document.save();
					else if (control && key == Platform.KEY_A)
						document.buffer.selectAll();
					else if (control && key == Platform.KEY_Z)
						document.undo();
					else if (control && key == Platform.KEY_Y)
						document.redo();
					else if (key == Platform.KEY_BACKSPACE)
						document.backspace();
					else if (key == Platform.KEY_DELETE)
						document.deleteForward();
					else if (key == Platform.KEY_ENTER)
						document.insert("\n");
					else if (key == Platform.KEY_TAB)
						document.insert("\t");
					else if (key == Platform.KEY_LEFT)
						document.buffer.move(-1, shift);
					else if (key == Platform.KEY_RIGHT)
						document.buffer.move(1, shift);
					else if (key == Platform.KEY_UP)
						view.moveVertical(-1, shift);
					else if (key == Platform.KEY_DOWN)
						view.moveVertical(1, shift);
					else if (key == Platform.KEY_HOME)
						document.buffer.moveHome(shift);
					else if (key == Platform.KEY_END)
						document.buffer.moveEnd(shift);
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
