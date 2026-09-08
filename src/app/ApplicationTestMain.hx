package app;

import core.Application;
import editor.Document;
import platform.Native;
import platform.Platform;
import renderer.Renderer;
import view.LayoutKind;
import view.LayoutNode;
import editor.BufferSelection;

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
		var untitledOne = application.documents.createUntitled(), untitledTwo = application.documents.createUntitled();
		require(untitledOne != untitledTwo && untitledOne.id != untitledTwo.id && !untitledOne.hasBackingPath() && !untitledOne.save(),
			"untitled documents were not distinct or attempted persistence without Save As");
		application.documents.close(untitledOne, true);
		application.documents.close(untitledTwo, true);
		require(application.documents.documents.length == 2 && application.root.tabs.views.length == 2, "documents did not open as tabs");
		require(application.add(second) == secondView && application.root.tabs.views.length == 2, "document tab was not reused");
		require(application.focus.activeView == secondView, "new tab did not receive focus");
		application.commands.perform("doc:newline", application.context);
		require(second.buffer.text == "\ntwo" && first.buffer.text == "one", "command did not target active document");
		application.commands.perform("root:switch-to-previous-tab", application.context);
		require(application.focus.activeView == firstView, "tab switch did not update focus");
		application.commands.perform("doc:newline", application.context);
		require(first.buffer.text == "\none", "command context captured the wrong document");
		require(application.requestCloseActiveTab() && application.root.commandView.active, "dirty document close did not request a decision");
		application.textInput("cancel");
		application.keyPressed(Platform.KEY_ENTER, 0);
		require(application.documents.documents.indexOf(first) >= 0, "cancelled document close released the document");
		require(!application.root.commandView.active, "cancelled document close left its prompt active");
		require(application.requestCloseActiveTab(), "document close could not restart after cancellation");
		application.textInput("discard");
		application.keyPressed(Platform.KEY_ENTER, 0);
		require(application.documents.documents.length == 1 && application.focus.activeView == secondView,
			"closing a tab did not reconcile ownership and focus");
		application.commands.perform("root:split-right", application.context);
		require(!application.root.node.isLeaf() && application.root.node.requireFirst().width + application.root.node.requireSecond().width
			+ LayoutNode.DIVIDER_SIZE == 640 - view.Sidebar.WIDTH, "horizontal split did not assign recursive bounds");
		require(application.documents.documents.length == 1 && application.root.node.containsDocument(second),
			"split duplicated document ownership");
		var leftView = application.root.node.requireFirst().tabs.activeView, rightView = application.root.node.requireSecond().tabs.activeView;
		if (leftView == null || rightView == null) throw "split views are missing";
		leftView.restoreCursor(1, 1);
		rightView.restoreCursor(1, 2);
		application.root.activateLeaf(application.root.node.requireFirst());
		require(leftView.cursorLine() == 1 && leftView.cursorColumn() == 1, "left pane did not restore its cursor");
		application.root.activateLeaf(application.root.node.requireSecond());
		require(rightView.cursorLine() == 1 && rightView.cursorColumn() == 2, "right pane did not retain an independent cursor");
		rightView.restoreCursor(0, 0);
		application.commands.perform("doc:newline", application.context);
		application.root.activateLeaf(application.root.node.requireFirst());
		require(leftView.cursorLine() == 2 && leftView.cursorColumn() == 1,
			"edit in one pane did not transform the other pane's cursor");
		application.root.activateLeaf(application.root.node.requireSecond());
		var divider = application.root.node.requireFirst().x + application.root.node.requireFirst().width;
		application.root.mouseDown(Platform.MOUSE_LEFT, divider + 1, 100);
		application.root.mouseMove(520, 100);
		application.root.mouseUp(Platform.MOUSE_LEFT);
		require(application.root.node.divider > 600, "divider drag did not resize panes");
		application.commands.perform("root:split-up", application.context);
		require(!application.root.node.requireSecond().isLeaf()
			&& application.root.node.requireSecond().kind == LayoutKind.Vertical, "nested vertical split was not created");
		renderer.begin();
		application.root.draw();
		renderer.present();
		require(application.requestCloseActivePane() && !application.root.commandView.active && !application.root.node.isLeaf(),
			"shared-document pane close prompted or failed to collapse");
		require(application.root.closeActivePane(true) && application.root.node.isLeaf(), "closing final pane did not collapse layout root");
		var failing = new Document("/missing-parent/failure.txt", "clean", application.syntaxes);
		failing.insert(new BufferSelection(), "dirty");
		application.add(failing);
		require(application.requestCloseActiveTab(), "failed-save close did not start");
		application.textInput("save");
		application.keyPressed(Platform.KEY_ENTER, 0);
		require(application.documents.documents.indexOf(failing) >= 0 && failing.dirty && !application.root.commandView.active,
			"failed save closed or cleaned the document");
		var quitOther = application.documents.createUntitled();
		quitOther.insert(new BufferSelection(), "quit dirty");
		require(application.requestQuit(), "quit coordination did not start");
		application.textInput("discard");
		application.keyPressed(Platform.KEY_ENTER, 0);
		application.textInput("cancel");
		application.keyPressed(Platform.KEY_ENTER, 0);
		require(!application.quitReady && application.documents.documents.indexOf(failing) >= 0
			&& application.documents.documents.indexOf(quitOther) >= 0, "cancel during multi-document quit released state");
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
