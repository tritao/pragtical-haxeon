package app;

import platform.Native;
import platform.Platform;
import editor.Document;
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
		while (running) {
			while (Native.event_poll()) {
				var kind = Native.event_kind();
				if (kind == Platform.EVENT_QUIT)
					running = false;
				else if (kind == Platform.EVENT_TEXT_INPUT)
					document.insert(Native.event_text());
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
					else if (key == Platform.KEY_HOME)
						document.buffer.moveHome(shift);
					else if (key == Platform.KEY_END)
						document.buffer.moveEnd(shift);
				}
			}
			renderer.begin();
			renderer.rect(0, 0, 960, 42, 0x252525ff);
			renderer.rect(0, 42, 220, 598, 0x202020ff);
			renderer.text(18, 13, "PRAGTICAL HAXEON", 0xe6e6e6ff);
			renderer.text(18, 62, "EXPLORER", 0xaaaaaaff);
			renderer.text(244, 13, (document.dirty ? "* " : "") + path, 0xccccccff);
			var lines = document.buffer.text.split("\n"), visibleLines = Std.int((640 - 54) / renderer.lineHeight),
				visible = lines.length < visibleLines ? lines.length : visibleLines;
			for (lineIndex in 0...visible)
				renderer.text(244, 54 + lineIndex * renderer.lineHeight, lines[lineIndex], 0xe6e6e6ff);
			var cursorLine = document.buffer.cursorLine(), cursorColumn = document.buffer.cursorColumn(),
				caretPrefix = cursorLine < lines.length ? lines[cursorLine].substr(0, cursorColumn) : "",
				caretX = 244 + renderer.textWidth(caretPrefix), caretY = 54 + cursorLine * renderer.lineHeight;
			renderer.rect(caretX, caretY, 2, renderer.lineHeight, 0xffffffff);
			renderer.present();
		}
		renderer.destroy();
		Platform.require(Native.window_destroy(window), "destroy editor window");
		Native.shutdown();
		return 0;
	}
}
