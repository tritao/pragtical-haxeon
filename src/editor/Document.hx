package editor;

import sys.io.File;
import syntax.Highlighter;
import syntax.SyntaxDefinition;

class Document {
	public final path:String;
	public final buffer:TextBuffer;
	public final highlighter:Highlighter;
	public final syntax:SyntaxDefinition;
	public var dirty(get, never):Bool;
	var savedStateId:Int;

	public function new(path:String, text:String) {
		this.path = path;
		buffer = new TextBuffer(text);
		syntax = SyntaxDefinition.forPath(path);
		highlighter = new Highlighter(buffer, syntax);
		buffer.onChange = highlighter.invalidate;
		savedStateId = buffer.stateId;
	}

	function get_dirty():Bool
		return buffer.stateId != savedStateId;

	public static function open(path:String):Document
		return new Document(path, File.getContent(path));

	public function insert(text:String):Void
		buffer.insert(text);

	public function backspace():Void {
		buffer.deleteBackward();
	}

	public function deleteForward():Void {
		buffer.deleteForward();
	}

	public function undo():Void {
		buffer.undo();
	}

	public function redo():Void {
		buffer.redo();
	}

	public function save():Void {
		File.saveContent(path, buffer.text);
		savedStateId = buffer.stateId;
	}
}
