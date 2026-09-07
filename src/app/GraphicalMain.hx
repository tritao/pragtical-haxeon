package app;

import platform.Native;
import platform.Platform;
import editor.Document;

class GraphicalMain {
	static function main():Int {
		if (Native.abi_version() != Platform.ABI_VERSION)
			throw "platform ABI version mismatch";
		Platform.require(Native.init(false), "initialize graphical platform");
		var arguments = Sys.args(), path = arguments.length == 0 ? "README.md" : arguments[0], document = Document.open(path);
		var window = Native.window_create("Pragtical Haxeon", 960, 640), running = true;
		Platform.require(window != 0, "create editor window");
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
			Platform.require(Native.frame_begin(window), "begin frame");
			Platform.require(Native.draw_rect(window, 0, 0, 960, 42, 0x252525ff), "draw title bar");
			Platform.require(Native.draw_rect(window, 0, 42, 220, 598, 0x202020ff), "draw sidebar");
			Platform.require(Native.draw_text(window, 18, 17, "PRAGTICAL HAXEON", 0xe6e6e6ff), "draw title");
			Platform.require(Native.draw_text(window, 18, 68, "EXPLORER", 0xaaaaaaff), "draw explorer");
			Platform.require(Native.draw_text(window, 244, 17, (document.dirty ? "* " : "") + path, 0xccccccff), "draw filename");
			var lines = document.buffer.text.split("\n"), visible = lines.length < 65 ? lines.length : 65;
			for (lineIndex in 0...visible)
				Platform.require(Native.draw_text(window, 244, 58 + lineIndex * 9, lines[lineIndex], 0xe6e6e6ff), "draw document line");
			var caretX = 244 + document.buffer.cursorColumn() * 8, caretY = 58 + document.buffer.cursorLine() * 9;
			Platform.require(Native.draw_rect(window, caretX, caretY, 2, 8, 0xffffffff), "draw caret");
			Platform.require(Native.frame_present(window), "present frame");
		}
		Platform.require(Native.window_destroy(window), "destroy editor window");
		Native.shutdown();
		return 0;
	}
}
