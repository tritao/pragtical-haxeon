package app;

import core.Application;
import platform.Native;
import platform.Platform;
import renderer.Renderer;

class BuildTaskSmokeMain {
	static function require(condition:Bool, message:String):Void {
		if (!condition) throw message;
	}

	static function main():Int {
		var arguments = Sys.args();
		require(arguments.length == 1, "build task smoke requires repository root");
		Platform.startHeadless();
		var window = Native.window_create("build-task-smoke", 640, 320), renderer = new Renderer(window, "ignored-headlessly.ttf", 15),
			application = new Application(renderer, 640, 320);
		application.workspace.addProject(arguments[0]);
		require(application.commands.perform("build:run-task", application.context) && application.root.commandView.results.length >= 2
			&& application.root.commandView.results[0].label == "build-headless", "repository build task was not offered deliberately");
		application.keyPressed(Platform.KEY_ENTER, 0);
		var deadline = Sys.time() + 60.0;
		while (application.build.active != null && Sys.time() < deadline) application.update();
		var transcript = [for (line in application.build.output.lines) line.text].join("\n");
		require(application.build.active == null && StringTools.endsWith(transcript, "Process exited with status 0")
			&& transcript.indexOf("compiled") >= 0, "repository headless build did not complete successfully through the task controller");
		application.shutdown();
		renderer.destroy();
		Platform.require(Native.window_destroy(window), "destroy build task smoke window");
		Native.shutdown();
		Sys.println("PASS: repository headless build ran through deliberate project task UI");
		return 0;
	}
}
