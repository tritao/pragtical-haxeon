package process;

import platform.Native;

class OwnedProcess {
	public final id:Int;
	var disposed:Bool = false;

	@:allow(process.ProcessManager)
	function new(id:Int) {
		this.id = id;
	}

	public function state():Int
		return disposed ? ProcessState.INVALID : Native.process_state(id);

	public function running():Bool
		return state() == ProcessState.RUNNING;

	public function exited():Bool
		return state() == ProcessState.EXITED;

	public function exitStatus():Int
		return disposed ? -1 : Native.process_exit_status(id);

	public function readStdout():String
		return disposed ? "" : Native.process_stdout(id);

	public function readStderr():String
		return disposed ? "" : Native.process_stderr(id);

	/** Atomically accepts the complete UTF-8 value, returns zero for backpressure, or throws. */
	public function writeStdin(data:String):Int {
		if (disposed) throw "process is disposed";
		var written = Native.process_write(id, data);
		if (written < 0) throw Native.last_error();
		return written;
	}

	public function closeStdin():Bool
		return !disposed && Native.process_close_stdin(id);

	public function cancel():Bool
		return !disposed && Native.process_cancel(id);

	public function dispose():Void {
		if (disposed) return;
		disposed = true;
		Native.process_destroy(id);
	}
}
