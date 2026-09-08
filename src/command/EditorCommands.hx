package command;

import platform.Platform;
import view.LayoutKind;

class EditorCommands {
	public static function install(registry:CommandRegistry, keymap:Keymap):Void {
		registry.add("doc:save", context -> context.requireDocument().save(), hasDocument);
		registry.add("doc:undo", context -> context.requireView().undo(), hasDocument);
		registry.add("doc:redo", context -> context.requireView().redo(), hasDocument);
		registry.add("doc:select-all", context -> context.requireView().selectAll(), hasDocument);
		registry.add("doc:backspace", context -> context.requireView().backspace(), hasDocument);
		registry.add("doc:delete", context -> context.requireView().deleteForward(), hasDocument);
		registry.add("doc:newline", context -> context.requireView().textInput("\n"), hasDocument);
		registry.add("doc:indent", context -> context.requireView().textInput("\t"), hasDocument);
		registry.add("doc:move-to-previous-char", context -> context.requireView().moveHorizontal(-1, false), hasDocument);
		registry.add("doc:move-to-next-char", context -> context.requireView().moveHorizontal(1, false), hasDocument);
		registry.add("doc:move-to-previous-line", context -> context.requireView().moveVertical(-1, false), hasDocument);
		registry.add("doc:move-to-next-line", context -> context.requireView().moveVertical(1, false), hasDocument);
		registry.add("doc:move-to-start-of-line", context -> context.requireView().moveHome(false), hasDocument);
		registry.add("doc:move-to-end-of-line", context -> context.requireView().moveEnd(false), hasDocument);
		registry.add("doc:select-to-previous-char", context -> context.requireView().moveHorizontal(-1, true), hasDocument);
		registry.add("doc:select-to-next-char", context -> context.requireView().moveHorizontal(1, true), hasDocument);
		registry.add("doc:select-to-previous-line", context -> context.requireView().moveVertical(-1, true), hasDocument);
		registry.add("doc:select-to-next-line", context -> context.requireView().moveVertical(1, true), hasDocument);
		registry.add("doc:select-to-start-of-line", context -> context.requireView().moveHome(true), hasDocument);
		registry.add("doc:select-to-end-of-line", context -> context.requireView().moveEnd(true), hasDocument);
		registry.add("root:switch-to-next-tab", context -> context.root.tabs.switchBy(1));
		registry.add("root:switch-to-previous-tab", context -> context.root.tabs.switchBy(-1));
		registry.add("root:close", context -> context.root.closeActiveTab(), context -> context.focus.activeView != null);
		registry.add("root:split-left", context -> context.root.splitActive(LayoutKind.Horizontal, true));
		registry.add("root:split-right", context -> context.root.splitActive(LayoutKind.Horizontal));
		registry.add("root:split-up", context -> context.root.splitActive(LayoutKind.Vertical, true));
		registry.add("root:split-down", context -> context.root.splitActive(LayoutKind.Vertical));
		registry.add("root:close-pane", context -> context.root.closeActivePane());
		registry.add("project:sidebar-next", context -> context.root.sidebarMove(1));
		registry.add("project:sidebar-previous", context -> context.root.sidebarMove(-1));
		registry.add("project:sidebar-open", context -> context.root.sidebarActivate());

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

	static function bindMovement(keymap:Keymap, key:Int, suffix:String):Void {
		keymap.addDirect(key, 0, ["doc:move-to-" + suffix]);
		keymap.addDirect(key, Platform.MOD_SHIFT, ["doc:select-to-" + suffix]);
	}
}
