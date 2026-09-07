package command;

import editor.Document;
import editor.EditorView;
import platform.Platform;

class EditorCommands {
	public static function install(registry:CommandRegistry, keymap:Keymap, document:Document, view:EditorView):Void {
		registry.add("doc:save", () -> document.save());
		registry.add("doc:undo", () -> document.undo());
		registry.add("doc:redo", () -> document.redo());
		registry.add("doc:select-all", () -> document.buffer.selectAll());
		registry.add("doc:backspace", () -> document.backspace());
		registry.add("doc:delete", () -> document.deleteForward());
		registry.add("doc:newline", () -> document.insert("\n"));
		registry.add("doc:indent", () -> document.insert("\t"));
		registry.add("doc:move-to-previous-char", () -> document.buffer.move(-1));
		registry.add("doc:move-to-next-char", () -> document.buffer.move(1));
		registry.add("doc:move-to-previous-line", () -> view.moveVertical(-1, false));
		registry.add("doc:move-to-next-line", () -> view.moveVertical(1, false));
		registry.add("doc:move-to-start-of-line", () -> document.buffer.moveHome());
		registry.add("doc:move-to-end-of-line", () -> document.buffer.moveEnd());
		registry.add("doc:select-to-previous-char", () -> document.buffer.move(-1, true));
		registry.add("doc:select-to-next-char", () -> document.buffer.move(1, true));
		registry.add("doc:select-to-previous-line", () -> view.moveVertical(-1, true));
		registry.add("doc:select-to-next-line", () -> view.moveVertical(1, true));
		registry.add("doc:select-to-start-of-line", () -> document.buffer.moveHome(true));
		registry.add("doc:select-to-end-of-line", () -> document.buffer.moveEnd(true));

		keymap.addDirect(Platform.KEY_S, Platform.MOD_CTRL, ["doc:save"]);
		keymap.addDirect(Platform.KEY_Z, Platform.MOD_CTRL, ["doc:undo"]);
		keymap.addDirect(Platform.KEY_Y, Platform.MOD_CTRL, ["doc:redo"]);
		keymap.addDirect(Platform.KEY_A, Platform.MOD_CTRL, ["doc:select-all"]);
		keymap.addDirect(Platform.KEY_TAB, 0, ["doc:indent"]);
		keymap.addDirect(Platform.KEY_ENTER, 0, ["doc:newline"]);
		keymap.addDirect(Platform.KEY_BACKSPACE, 0, ["doc:backspace"]);
		keymap.addDirect(Platform.KEY_BACKSPACE, Platform.MOD_SHIFT, ["doc:backspace"]);
		keymap.addDirect(Platform.KEY_DELETE, 0, ["doc:delete"]);
		keymap.addDirect(Platform.KEY_DELETE, Platform.MOD_SHIFT, ["doc:delete"]);
		bindMovement(keymap, Platform.KEY_LEFT, "previous-char");
		bindMovement(keymap, Platform.KEY_RIGHT, "next-char");
		bindMovement(keymap, Platform.KEY_UP, "previous-line");
		bindMovement(keymap, Platform.KEY_DOWN, "next-line");
		bindMovement(keymap, Platform.KEY_HOME, "start-of-line");
		bindMovement(keymap, Platform.KEY_END, "end-of-line");
	}

	static function bindMovement(keymap:Keymap, key:Int, suffix:String):Void {
		keymap.addDirect(key, 0, ["doc:move-to-" + suffix]);
		keymap.addDirect(key, Platform.MOD_SHIFT, ["doc:select-to-" + suffix]);
	}
}
