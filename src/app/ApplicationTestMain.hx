package app;

import core.Application;
import editor.Document;
import platform.Native;
import platform.Platform;
import renderer.Renderer;
import view.LayoutKind;
import view.LayoutNode;

class ApplicationTestMain {
	static function require(condition:Bool, message:String):Void {
		if (!condition) throw message;
	}

	static function main():Int {
		Platform.startHeadless();
		var window = Native.window_create("application-test", 640, 320), renderer = new Renderer(window, "ignored-headlessly.ttf", 15),
			application = new Application(renderer, 640, 320), first = new Document("first", "one", application.syntaxes),
			second = new Document("second", "two", application.syntaxes);
		var firstView = application.add(first), secondView = application.add(second);
		require(application.documents.documents.length == 2 && application.root.tabs.views.length == 2, "documents did not open as tabs");
		require(application.add(second) == secondView && application.root.tabs.views.length == 2, "document tab was not reused");
		require(application.focus.activeView == secondView, "new tab did not receive focus");
		application.commands.perform("doc:newline", application.context);
		require(second.buffer.text == "\ntwo" && first.buffer.text == "one", "command did not target active document");
		application.commands.perform("root:switch-to-previous-tab", application.context);
		require(application.focus.activeView == firstView, "tab switch did not update focus");
		application.commands.perform("doc:newline", application.context);
		require(first.buffer.text == "\none", "command context captured the wrong document");
		require(!application.root.closeActiveTab(), "dirty document closed without confirmation");
		require(application.root.closeActiveTab(true), "forced document close failed");
		require(application.documents.documents.length == 1 && application.focus.activeView == secondView,
			"closing a tab did not reconcile ownership and focus");
		application.commands.perform("root:split-right", application.context);
		require(!application.root.node.isLeaf() && application.root.node.requireFirst().width + application.root.node.requireSecond().width
			+ LayoutNode.DIVIDER_SIZE == 640, "horizontal split did not assign recursive bounds");
		require(application.documents.documents.length == 1 && application.root.node.containsDocument(second),
			"split duplicated document ownership");
		var divider = application.root.node.requireFirst().width;
		application.root.mouseDown(Platform.MOUSE_LEFT, divider + 1, 100);
		application.root.mouseMove(450, 100);
		application.root.mouseUp(Platform.MOUSE_LEFT);
		require(application.root.node.divider > 600, "divider drag did not resize panes");
		application.commands.perform("root:split-up", application.context);
		require(!application.root.node.requireSecond().isLeaf()
			&& application.root.node.requireSecond().kind == LayoutKind.Vertical, "nested vertical split was not created");
		renderer.begin();
		application.root.draw();
		renderer.present();
		require(application.root.closeActivePane(true) && !application.root.node.isLeaf(), "nested pane did not collapse into its sibling");
		require(application.root.closeActivePane(true) && application.root.node.isLeaf(), "closing final pane did not collapse layout root");
		renderer.begin();
		application.root.draw();
		renderer.present();
		renderer.destroy();
		Platform.require(Native.window_destroy(window), "destroy application test window");
		Native.shutdown();
		Sys.println("PASS: application document, tab, focus, command, and close ownership");
		return 0;
	}
}
