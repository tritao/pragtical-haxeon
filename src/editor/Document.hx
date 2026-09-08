package editor;

import sys.io.File;
import syntax.Highlighter;
import syntax.SyntaxDefinition;
import syntax.SyntaxRegistry;
import workspace.FileSystemService;
import workspace.EditorFileSystem;

class Document {
	public var path(default, null):String;
	public final buffer:TextBuffer;
	public var highlighter(default, null):Highlighter;
	public var syntax(default, null):SyntaxDefinition;
	final syntaxes:SyntaxRegistry;
	final fileSystem:EditorFileSystem;
	public var dirty(get, never):Bool;
	public var externalState(default, null):ExternalState = Current;
	var diskContent:String;
	var newline:String = "\n";
	var hasBom:Bool = false;
	var savedStateId:Int;

	public function new(path:String, text:String, registry:SyntaxRegistry, ?fileSystem:EditorFileSystem) {
		this.path = path;
		this.syntaxes = registry;
		this.fileSystem = fileSystem == null ? new FileSystemService() : fileSystem;
		buffer = new TextBuffer(text);
		diskContent = text;
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

	public static function open(path:String, registry:SyntaxRegistry, ?fileSystem:EditorFileSystem):Document {
		var service = fileSystem == null ? new FileSystemService() : fileSystem;
		var raw = service.read(path), bom = StringTools.startsWith(raw, "﻿");
		var body = bom ? raw.substring(1) : raw, newline = body.indexOf("\r\n") >= 0 ? "\r\n" : "\n";
		body = StringTools.replace(StringTools.replace(body, "\r\n", "\n"), "\r", "\n");
		var document = new Document(path, body, registry, service);
		document.hasBom = bom;
		document.newline = newline;
		document.diskContent = raw;
		return document;
	}

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

	public function save(force:Bool = false):Bool {
		checkExternal();
		if (externalState != Current && !force) return false;
		var encoded = encode(buffer.text);
		if (!fileSystem.writeAtomic(path, encoded)) return false;
		savedStateId = buffer.stateId;
		diskContent = encoded;
		externalState = Current;
		return true;
	}

	public function checkExternal():ExternalState {
		if (!fileSystem.exists(path)) {
			externalState = Deleted;
			return externalState;
		}
		var content:String;
		try {
			content = fileSystem.read(path);
		} catch (error:Dynamic) {
			externalState = Changed;
			return externalState;
		}
		if (content == diskContent) {
			externalState = Current;
			return externalState;
		}
		if (dirty) {
			externalState = Changed;
			return externalState;
		}
		var bom = StringTools.startsWith(content, "﻿"), body = bom ? content.substring(1) : content;
		hasBom = bom;
		newline = body.indexOf("\r\n") >= 0 ? "\r\n" : "\n";
		body = StringTools.replace(StringTools.replace(body, "\r\n", "\n"), "\r", "\n");
		buffer.replaceAllText(body);
		savedStateId = buffer.stateId;
		diskContent = content;
		externalState = Current;
		return externalState;
	}

	public function acceptRecoveredText(text:String):Void {
		if (buffer.text != text) buffer.replaceAllText(text);
	}

	function encode(text:String):String {
		var body = newline == "\n" ? text : StringTools.replace(text, "\n", newline);
		return hasBom ? "﻿" + body : body;
	}
}
