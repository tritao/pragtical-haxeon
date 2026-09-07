package command;

import core.DocumentManager;
import core.FocusManager;
import view.RootView;
import view.View;

class CommandContext {
	public final root:RootView;
	public final focus:FocusManager;
	public final documents:DocumentManager;

	public function new(root:RootView, focus:FocusManager, documents:DocumentManager) {
		this.root = root;
		this.focus = focus;
		this.documents = documents;
	}

	public function activeView():Null<View>
		return focus.activeView;
}
