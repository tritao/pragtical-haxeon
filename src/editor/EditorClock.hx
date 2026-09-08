package editor;

interface EditorClock {
	function now():Float;
}

class SystemEditorClock implements EditorClock {
	public function new() {}
	public function now():Float return Sys.time();
}
