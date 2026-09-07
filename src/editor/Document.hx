package editor;

import sys.io.File;
import syntax.Highlighter;
import syntax.SyntaxDefinition;
import syntax.SyntaxRegistry;

class Document {
	public var path(default, null):String;
	public final buffer:TextBuffer;
	public var highlighter(default, null):Highlighter;
	public var syntax(default, null):SyntaxDefinition;
	final syntaxes:SyntaxRegistry;
	public var dirty(get, never):Bool;
	var savedStateId:Int;

	public function new(path:String, text:String, registry:SyntaxRegistry) {
		this.path = path;
		this.syntaxes = registry;
		buffer = new TextBuffer(text);
		selectSyntax();
		savedStateId = buffer.stateId;
	}

	function get_dirty():Bool
		return buffer.stateId != savedStateId;

	public function setPath(path:String):Void {
		this.path = path;
		selectSyntax();
	}

	function selectSyntax():Void {
		syntax = syntaxes.find(path, buffer.text.substr(0, 128));
		highlighter = new Highlighter(buffer, syntax);
		buffer.onChange = highlighter.invalidate;
	}

	public static function open(path:String, registry:SyntaxRegistry):Document
		return new Document(path, File.getContent(path), registry);

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
