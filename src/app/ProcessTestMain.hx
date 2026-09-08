package app;

import process.OwnedProcess;
import process.ProcessManager;
import platform.Native;
import platform.Platform;

class ProcessTestMain {
	static function require(condition:Bool, message:String):Void {
		if (!condition) throw message;
	}

	static function collect(process:OwnedProcess, timeout:Float):Array<String> {
		var output = "", errors = "", deadline = Sys.time() + timeout, settled = 0;
		while (Sys.time() < deadline && settled < 2) {
			var stdout = process.readStdout(), stderr = process.readStderr();
			output += stdout;
			errors += stderr;
			if (process.exited() && stdout.length == 0 && stderr.length == 0) settled++; else settled = 0;
		}
		require(settled >= 2, "process did not exit and drain before timeout");
		return [output, errors];
	}

	static function main():Int {
		Platform.startHeadless();
		var arguments = Sys.args();
		require(arguments.length == 2, "process test requires fixture and cwd");
		var fixture = arguments[0], cwd = arguments[1], manager = new ProcessManager(), environment:Map<String, String> = [];
		environment.set("PHX_TEST", "environment value");
		var inspected = manager.start(fixture, ["inspect", "argument with spaces"], cwd, environment), streams = collect(inspected, 5.0);
		require(inspected.exitStatus() == 0 && streams[0].indexOf("cwd=" + cwd) >= 0
			&& streams[0].indexOf("env=environment value") >= 0 && streams[0].indexOf("arg=argument with spaces") >= 0
			&& streams[1] == "fixture-stderr\n", "process arguments, cwd, environment, or split output were corrupted");
		var stale = inspected.id;
		require(manager.release(inspected) && Native.process_state(stale) == 0, "released process handle was not stale");

		var failed = manager.start(fixture, ["exit", "7"]), failureStreams = collect(failed, 5.0);
		require(failureStreams[0] == "" && failed.exitStatus() == 7, "nonzero process exit status was lost");
		manager.release(failed);

		var flooded = manager.start(fixture, ["flood", "200000"]), floodStreams = collect(flooded, 5.0);
		require(flooded.exitStatus() == 0 && floodStreams[0].length == 200000, "nonblocking process output was truncated or hung");
		manager.release(flooded);

		var cancelled = manager.start(fixture, ["sleep"]);
		require(cancelled.cancel(), "process cancellation request failed");
		collect(cancelled, 5.0);
		require(cancelled.exitStatus() >= 128, "cancelled process did not report a signal exit");
		manager.release(cancelled);
		manager.start(fixture, ["sleep"]);
		manager.shutdown();
		require(manager.activeCount() == 0, "process manager shutdown retained owned processes");
		Native.shutdown();
		Sys.println("PASS: owned nonblocking processes, exact launch configuration, cancellation, and cleanup");
		return 0;
	}
}
