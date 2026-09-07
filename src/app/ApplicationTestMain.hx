package app;

import core.Application;
import editor.Document;
import platform.Native;
import platform.Platform;
import renderer.Renderer;

class ApplicationTestMain {
	static function require(condition:Bool, message:String):Void {
		if (!condition) throw message;
	}

	static function main():Int {
		Platform.startHeadless();
		var window = Native.window_create("application-test", 640, 320), renderer = new Renderer(window, "ignored-headlessly.ttf", 15),
			application = new Application(renderer, 640, 320), first = new Document("first", "one"), second = new Document("second", "two");
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
		require(!application.root.tabs.closeActive(), "dirty document closed without confirmation");
		require(application.root.tabs.closeActive(true), "forced document close failed");
		require(application.documents.documents.length == 1 && application.focus.activeView == secondView,
			"closing a tab did not reconcile ownership and focus");
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
