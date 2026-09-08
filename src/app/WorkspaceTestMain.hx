package app;

import core.Application;
import platform.Native;
import platform.Platform;
import renderer.Renderer;
import session.WorkspaceSession;
import view.LayoutKind;
import editor.BufferSelection;
import jobs.JobTask;
import jobs.JobScheduler;

private class CountingJob implements JobTask {
	public var steps:Int = 0;
	public var cancelled:Bool = false;
	final target:Int;

	public function new(target:Int) this.target = target;
	public function step():Bool {
		steps++;
		return steps >= target;
	}
	public function cancel():Void cancelled = true;
}

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
		var scheduler = new JobScheduler(), firstJob = new CountingJob(3), firstHandle = scheduler.schedule(firstJob);
		require(scheduler.update(2) == 2 && firstJob.steps == 2 && scheduler.activeCount() == 1,
			"job scheduler exceeded its bounded update or retired work early");
		var replacementJob = new CountingJob(1), replacementHandle = scheduler.replace(firstHandle, replacementJob);
		require(firstJob.cancelled && replacementHandle.id == firstHandle.id && replacementHandle.generation == firstHandle.generation + 1
			&& !scheduler.cancel(firstHandle), "job generation did not reject a stale handle");
		require(scheduler.update(1) == 1 && replacementJob.steps == 1 && scheduler.activeCount() == 0,
			"replacement job did not complete and retire");
		require(application.workspace.activeProject == project && visible.length == 4, "project root did not scan or ignored entries leaked");
		require(visible[0] == project.tree && visible[1].name == "alpha.txt" && visible[2].name == "binary.dat" && visible[3].name == "src",
			"project tree ordering failed");
		project.restoreExpanded([arguments[0] + "/src"]);
		application.workspace.refreshProjects(32);
		require(project.visibleNodes().length == 5 && project.visibleNodes()[4].name == "Main.hx", "directory expansion failed");
		application.commands.perform("project:sidebar-next", application.context);
		application.commands.perform("project:sidebar-open", application.context);
		require(application.documents.documents.length == 1 && application.documents.documents[0].path == visible[1].path,
			"sidebar command did not open selected file");
		application.root.mouseDown(Platform.MOUSE_LEFT, 20, view.Sidebar.HEADER_HEIGHT + view.Sidebar.ROW_HEIGHT * 3 + 1);
		require(!visible[3].expanded && application.root.sidebar.selected == 3, "sidebar mouse did not select and collapse directory");
		require(application.keyPressed(Platform.KEY_P, Platform.MOD_CTRL) && application.root.commandView.active, "Ctrl+P did not open file command view");
		application.textInput("main");
		require(application.root.commandView.results.length == 1 && application.root.commandView.results[0].label == "src/Main.hx",
			"file command view fuzzy filtering failed");
		application.keyPressed(Platform.KEY_ENTER, 0);
		require(application.documents.documents.length == 2 && !application.root.commandView.active, "file command view did not accept selection");
		var secondProject = application.workspace.addProject(arguments[1]);
		application.root.tabs.activeView.textInput("needle ");
		require(application.keyPressed(Platform.KEY_F, Platform.MOD_CTRL), "Ctrl+F did not open document find");
		application.textInput("needle");
		require(application.documentMatches.length == 1 && application.root.tabs.activeView.hasSelection(),
			"document find did not select an unsaved match");
		application.keyPressed(Platform.KEY_ESCAPE, 0);
		application.textInput("changed");
		require(application.documentMatches.length == 0, "document find retained a stale match after editing");
		application.root.tabs.activeView.undo();
		application.commands.perform("find:next", application.context);
		require(application.documentMatches.length == 1, "document find did not refresh after undo");
		require(application.replaceAll("found") == 1 && application.documents.documents[1].buffer.text.indexOf("needle") < 0,
			"replace all did not apply as one document operation");
		application.root.tabs.activeView.undo();
		require(application.documents.documents[1].buffer.text.indexOf("needle") >= 0, "one undo did not restore replace all");
		application.openDocumentFind();
		application.textInput("needle");
		application.keyPressed(Platform.KEY_ESCAPE, 0);
		require(application.root.tabs.activeView != null && application.root.tabs.activeView.searchMatchCount() == 0,
			"cancelled find retained transient highlights");
		application.root.tabs.switchBy(-1);
		application.commands.perform("find:next", application.context);
		require(application.documentMatches.length == 0, "document find results leaked across active documents");
		application.root.tabs.switchBy(1);
		require(application.keyPressed(Platform.KEY_F, Platform.MOD_CTRL + Platform.MOD_SHIFT), "Ctrl+Shift+F did not open workspace search");
		application.textInput("needle");
		application.workspaceSearch.flush();
		application.workspace.jobs.update(32);
		require(application.root.searchVisible && application.root.searchSidebar.results.length == 2,
			"workspace search did not include unsaved and multi-project matches: results="
			+ [for (match in application.workspaceSearch.results) match.path].join(",") + ", errors="
			+ application.workspaceSearch.errors.join(",") + ", complete=" + application.workspaceSearch.complete
			+ ", jobs=" + application.workspace.jobs.activeCount());
		require(application.workspaceSearch.complete && application.workspaceSearch.errors.length == 1
			&& application.workspaceSearch.results[0].document != null,
			"workspace search did not prefer dirty buffers or report skipped binary input");
		var staleGeneration = application.workspaceSearch.generation;
		application.workspaceSearch.request("never-present", application.searchOptions, 100);
		application.workspaceSearch.flush();
		application.workspace.jobs.update(1);
		application.workspaceSearch.request("needle", application.searchOptions, 1);
		application.workspaceSearch.flush();
		application.workspace.jobs.update(32);
		require(application.workspaceSearch.generation > staleGeneration && application.workspaceSearch.results.length == 1
			&& application.workspaceSearch.capped, "replacement search published stale results or ignored its cap");
		application.searchOptions.pathFilter = "second.txt";
		application.workspaceSearch.request("needle", application.searchOptions, 100);
		application.workspaceSearch.flush();
		application.workspace.jobs.update(32);
		require(application.workspaceSearch.results.length == 1
			&& StringTools.endsWith(application.workspaceSearch.results[0].path, "/second.txt"), "workspace path filtering failed");
		application.searchOptions.pathFilter = "";
		application.searchOptions.regularExpression = true;
		application.workspaceSearch.request("nee(dle)", application.searchOptions, 100);
		application.workspaceSearch.flush();
		application.workspace.jobs.update(32);
		require(application.workspaceSearch.results.length == 2 && application.workspaceSearch.results[0].captures[1] == "dle",
			"workspace regular-expression search did not preserve captures");
		application.workspaceSearch.request("(", application.searchOptions, 100);
		application.workspaceSearch.flush();
		require(application.workspaceSearch.complete && application.workspaceSearch.errors.length == 1,
			"invalid workspace regular expression did not become a visible error");
		application.searchOptions.regularExpression = false;
		application.workspaceSearch.request("needle", application.searchOptions, 100);
		application.workspaceSearch.flush();
		application.workspace.jobs.update(32);
		application.keyPressed(Platform.KEY_ENTER, 0);
		require(application.root.searchSidebar.active() != null, "workspace result activation failed");
		application.keyPressed(Platform.KEY_ESCAPE, 0);
		application.commands.perform("project:show-sidebar", application.context);
		require(!application.root.searchVisible, "workspace search could not return to the project sidebar");
		application.commands.perform("project:sidebar-next", application.context);
		require(application.keyPressed(Platform.KEY_P, Platform.MOD_CTRL + Platform.MOD_SHIFT), "Ctrl+Shift+P did not open command palette");
		application.textInput("sidebarprevious");
		require(application.root.commandView.results.length == 1, "command view fuzzy filtering failed");
		application.keyPressed(Platform.KEY_ENTER, 0);
		require(application.root.sidebar.selected == 0,
			"command palette did not dispatch selected command: selected=" + application.root.sidebar.selected);
		application.openFileCommandView();
		application.keyPressed(Platform.KEY_ESCAPE, 0);
		require(!application.root.commandView.active, "Escape did not cancel command view");
		var createdPath = arguments[0] + "/created.txt", movedPath = arguments[0] + "/moved.txt";
		for (index in 0...16) application.workspace.refreshProjects(1);
		require(application.workspace.fileSystem.createFile(createdPath), "file creation failed");
		for (index in 0...16) application.workspace.refreshProjects(1);
		require(project.files().length == 4,
			"incremental polling missed created file: generation=" + project.indexGeneration() + ", indexing=" + project.indexing()
			+ ", jobs=" + application.workspace.jobs.activeCount() + ", files=" + [for (file in project.files()) file.path].join(","));
		var movedDocument = application.documents.open(createdPath);
		movedDocument.insert(new BufferSelection(), "moved safely");
		require(application.documents.rename(movedDocument, movedPath) && movedDocument.path == movedPath,
			"rename did not reconcile dirty open document identity");
		require(!application.documents.rename(movedDocument, arguments[0] + "/alpha.txt"), "rename overwrote a collision");
		require(movedDocument.save() && application.workspace.fileSystem.deleteFile(movedPath), "save/delete lifecycle failed");
		application.documents.close(movedDocument, true);
		for (index in 0...16) application.workspace.refreshProjects(1);
		require(project.files().length == 3, "incremental polling retained deleted file");
		project.restoreExpanded([arguments[0] + "/src"]);
		application.root.splitActive(LayoutKind.Horizontal);
		application.open(arguments[1] + "/second.txt");
		var session = WorkspaceSession.decode(WorkspaceSession.capture(application).encode());
		session.restore(application);
		require(application.root.sessionLines().join("\n") == session.layout.join("\n"), "layout tab order, active pane, cursor or scroll changed on restore");
		require(application.workspace.projects.length == 2 && !application.root.node.isLeaf()
			&& application.root.activeLeaf.tabs.activeView != null, "multi-root split session did not restore");
		require(project.visibleNodes().length == 5, "expanded project folders did not restore");
		require(application.workspace.removeProject(secondProject) && application.workspace.projects.length == 1,
			"closing a project did not retire its indexed state");
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
