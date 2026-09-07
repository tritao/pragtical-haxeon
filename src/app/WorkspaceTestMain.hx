package app;

import core.Application;
import platform.Native;
import platform.Platform;
import renderer.Renderer;

class WorkspaceTestMain {
	static function require(condition:Bool, message:String):Void {
		if (!condition) throw message;
	}

	static function main():Int {
		var arguments = Sys.args();
		require(arguments.length == 2, "expected project roots");
		Platform.startHeadless();
		var window = Native.window_create("workspace-test", 640, 320), renderer = new Renderer(window, "ignored-headlessly.ttf", 15),
			application = new Application(renderer, 640, 320), project = application.workspace.addProject(arguments[0], [".cache"]),
			visible = project.visibleNodes();
		require(application.workspace.activeProject == project && visible.length == 3, "project root did not scan or ignored entries leaked");
		require(visible[0] == project.tree && visible[1].name == "alpha.txt" && visible[2].name == "src", "project tree ordering failed");
		project.toggle(visible[2]);
		require(project.visibleNodes().length == 4 && project.visibleNodes()[3].name == "Main.hx", "directory expansion failed");
		application.commands.perform("project:sidebar-next", application.context);
		application.commands.perform("project:sidebar-open", application.context);
		require(application.documents.documents.length == 1 && application.documents.documents[0].path == visible[1].path,
			"sidebar command did not open selected file");
		application.root.mouseDown(Platform.MOUSE_LEFT, 20, view.Sidebar.HEADER_HEIGHT + view.Sidebar.ROW_HEIGHT * 2 + 1);
		require(!visible[2].expanded && application.root.sidebar.selected == 2, "sidebar mouse did not select and collapse directory");
		require(application.keyPressed(Platform.KEY_P, Platform.MOD_CTRL) && application.root.commandView.active, "Ctrl+P did not open file command view");
		application.textInput("main");
		require(application.root.commandView.results.length == 1 && application.root.commandView.results[0].label == "src/Main.hx",
			"file command view fuzzy filtering failed");
		application.keyPressed(Platform.KEY_ENTER, 0);
		require(application.documents.documents.length == 2 && !application.root.commandView.active, "file command view did not accept selection");
		application.workspace.addProject(arguments[1]);
		application.documents.documents[1].insert("needle ");
		require(application.keyPressed(Platform.KEY_F, Platform.MOD_CTRL), "Ctrl+F did not open document find");
		application.textInput("needle");
		require(application.documentMatches.length == 1 && application.documents.documents[1].buffer.hasSelection(),
			"document find did not select an unsaved match");
		application.keyPressed(Platform.KEY_ESCAPE, 0);
		require(application.keyPressed(Platform.KEY_F, Platform.MOD_CTRL + Platform.MOD_SHIFT), "Ctrl+Shift+F did not open workspace search");
		application.textInput("needle");
		require(application.root.searchVisible && application.root.searchSidebar.results.length == 2,
			"workspace search did not include unsaved and multi-project matches");
		application.keyPressed(Platform.KEY_ENTER, 0);
		require(application.root.searchSidebar.active() != null, "workspace result activation failed");
		application.keyPressed(Platform.KEY_ESCAPE, 0);
		require(application.keyPressed(Platform.KEY_P, Platform.MOD_CTRL + Platform.MOD_SHIFT), "Ctrl+Shift+P did not open command palette");
		application.textInput("sidebarprevious");
		require(application.root.commandView.results.length == 1, "command view fuzzy filtering failed");
		application.keyPressed(Platform.KEY_ENTER, 0);
		require(application.root.sidebar.selected == 1, "command palette did not dispatch selected command");
		application.openFileCommandView();
		application.keyPressed(Platform.KEY_ESCAPE, 0);
		require(!application.root.commandView.active, "Escape did not cancel command view");
		renderer.begin();
		application.root.draw();
		renderer.present();
		application.shutdown();
		renderer.destroy();
		Platform.require(Native.window_destroy(window), "destroy workspace test window");
		Native.shutdown();
		Sys.println("PASS: workspace projects, command view, and document/workspace search");
		return 0;
	}
}
