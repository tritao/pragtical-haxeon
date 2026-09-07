package editor;

import sys.io.File;

class Document {
	public final path:String;
	public final buffer:TextBuffer;
	public var dirty(default, null):Bool;

	public function new(path:String, text:String) {
		this.path = path;
		buffer = new TextBuffer(text);
		dirty = false;
	}

	public static function open(path:String):Document
		return new Document(path, File.getContent(path));

	public function insert(text:String):Void {
		buffer.insert(text);
		dirty = true;
	}

	public function backspace():Void {
		var before = buffer.text;
		buffer.deleteBackward();
		if (buffer.text != before)
			dirty = true;
	}

	public function deleteForward():Void {
		var before = buffer.text;
		buffer.deleteForward();
		if (buffer.text != before)
			dirty = true;
	}

	public function undo():Void {
		if (buffer.undo())
			dirty = true;
	}

	public function redo():Void {
		if (buffer.redo())
			dirty = true;
	}

	public function save():Void {
		File.saveContent(path, buffer.text);
		dirty = false;
	}
}
