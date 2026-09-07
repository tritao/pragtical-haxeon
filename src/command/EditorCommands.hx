package command;

import editor.Document;
import platform.Platform;
import view.View;

class EditorCommands {
	public static function install(registry:CommandRegistry, keymap:Keymap):Void {
		registry.add("doc:save", context -> EditorCommands.document(context).save(), EditorCommands.hasDocument);
		registry.add("doc:undo", context -> EditorCommands.document(context).undo(), EditorCommands.hasDocument);
		registry.add("doc:redo", context -> EditorCommands.document(context).redo(), EditorCommands.hasDocument);
		registry.add("doc:select-all", context -> EditorCommands.document(context).buffer.selectAll(), EditorCommands.hasDocument);
		registry.add("doc:backspace", context -> EditorCommands.document(context).backspace(), EditorCommands.hasDocument);
		registry.add("doc:delete", context -> EditorCommands.document(context).deleteForward(), EditorCommands.hasDocument);
		registry.add("doc:newline", context -> EditorCommands.document(context).insert("\n"), EditorCommands.hasDocument);
		registry.add("doc:indent", context -> EditorCommands.document(context).insert("\t"), EditorCommands.hasDocument);
		registry.add("doc:move-to-previous-char", context -> EditorCommands.document(context).buffer.move(-1), EditorCommands.hasDocument);
		registry.add("doc:move-to-next-char", context -> EditorCommands.document(context).buffer.move(1), EditorCommands.hasDocument);
		registry.add("doc:move-to-previous-line", context -> EditorCommands.view(context).moveVertical(-1, false), EditorCommands.hasDocument);
		registry.add("doc:move-to-next-line", context -> EditorCommands.view(context).moveVertical(1, false), EditorCommands.hasDocument);
		registry.add("doc:move-to-start-of-line", context -> EditorCommands.document(context).buffer.moveHome(), EditorCommands.hasDocument);
		registry.add("doc:move-to-end-of-line", context -> EditorCommands.document(context).buffer.moveEnd(), EditorCommands.hasDocument);
		registry.add("doc:select-to-previous-char", context -> EditorCommands.document(context).buffer.move(-1, true), EditorCommands.hasDocument);
		registry.add("doc:select-to-next-char", context -> EditorCommands.document(context).buffer.move(1, true), EditorCommands.hasDocument);
		registry.add("doc:select-to-previous-line", context -> EditorCommands.view(context).moveVertical(-1, true), EditorCommands.hasDocument);
		registry.add("doc:select-to-next-line", context -> EditorCommands.view(context).moveVertical(1, true), EditorCommands.hasDocument);
		registry.add("doc:select-to-start-of-line", context -> EditorCommands.document(context).buffer.moveHome(true), EditorCommands.hasDocument);
		registry.add("doc:select-to-end-of-line", context -> EditorCommands.document(context).buffer.moveEnd(true), EditorCommands.hasDocument);
		registry.add("root:switch-to-next-tab", function(context:CommandContext) { context.root.tabs.switchBy(1); });
		registry.add("root:switch-to-previous-tab", function(context:CommandContext) { context.root.tabs.switchBy(-1); });
		registry.add("root:close", function(context:CommandContext) { context.root.tabs.closeActive(); },
			(context:CommandContext) -> context.focus.activeView != null);

		keymap.addDirect(Platform.KEY_S, Platform.MOD_CTRL, ["doc:save"]);
		keymap.addDirect(Platform.KEY_Z, Platform.MOD_CTRL, ["doc:undo"]);
		keymap.addDirect(Platform.KEY_Y, Platform.MOD_CTRL, ["doc:redo"]);
		keymap.addDirect(Platform.KEY_A, Platform.MOD_CTRL, ["doc:select-all"]);
		keymap.addDirect(Platform.KEY_W, Platform.MOD_CTRL, ["root:close"]);
		keymap.addDirect(Platform.KEY_TAB, Platform.MOD_CTRL, ["root:switch-to-next-tab"]);
		keymap.addDirect(Platform.KEY_TAB, Platform.MOD_CTRL + Platform.MOD_SHIFT, ["root:switch-to-previous-tab"]);
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

	static function hasDocument(context:CommandContext):Bool
		return context.focus.activeView != null && context.focus.activeView.getDocument() != null;

	static function view(context:CommandContext):View
		return cast context.focus.activeView;

	static function document(context:CommandContext):Document
		return cast context.focus.activeView.getDocument();

	static function bindMovement(keymap:Keymap, key:Int, suffix:String):Void {
		keymap.addDirect(key, 0, ["doc:move-to-" + suffix]);
		keymap.addDirect(key, Platform.MOD_SHIFT, ["doc:select-to-" + suffix]);
	}
}
