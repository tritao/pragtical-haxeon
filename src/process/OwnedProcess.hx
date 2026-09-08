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

	public function cancel():Bool
		return !disposed && Native.process_cancel(id);

	public function dispose():Void {
		if (disposed) return;
		disposed = true;
		Native.process_destroy(id);
	}
}
