package app;

import platform.Native;
import platform.Platform;
import syntax.BuiltinSyntax;
import syntax.SyntaxRegistry;
import workspace.Workspace;

class ProjectIndexBenchmarkMain {
	static function main():Int {
		var arguments = Sys.args();
		if (arguments.length != 2) throw "expected project root and file count";
		var expected = Std.parseInt(arguments[1]), syntaxes = new SyntaxRegistry();
		BuiltinSyntax.install(syntaxes);
		Platform.startHeadless();
		var workspace = new Workspace(syntaxes), retired = workspace.addProject(arguments[0]), updates = 0, maximumMillis = 0.0;
		for (index in 0...5) workspace.refreshProjects(1);
		var retiredCount = retired.files().length;
		if (!workspace.removeProject(retired) || workspace.jobs.activeCount() != 0) throw "project cancellation retained its scan job";
		var project = workspace.addProject(arguments[0]);
		while (project.files().length < expected && updates < expected) {
			var started = Sys.time();
			workspace.refreshProjects(1);
			var elapsed = (Sys.time() - started) * 1000.0;
			if (elapsed > maximumMillis) maximumMillis = elapsed;
			updates++;
		}
		var indexed = project.files().length;
		if (retired.files().length != retiredCount) throw "retired project accepted stale scan results";
		Native.shutdown();
		if (indexed != expected) throw 'indexed $indexed of $expected files';
		Sys.println('PROJECT_INDEX files=$indexed updates=$updates max_update_ms=$maximumMillis input_ticks=$updates');
		return 0;
	}
}
