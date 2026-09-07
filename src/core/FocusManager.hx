package core;

import view.View;

class FocusManager {
	public var activeView(default, null):Null<View>;
	public var lastActiveView(default, null):Null<View>;

	public function new() {}

	public function activate(view:Null<View>):Void {
		if (activeView == view)
			return;
		lastActiveView = activeView;
		activeView = view;
	}
}
