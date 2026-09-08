package editor;

import sys.io.File;
import syntax.Highlighter;
import syntax.SyntaxDefinition;
import syntax.SyntaxRegistry;
import workspace.FileSystemService;
import workspace.EditorFileSystem;

class Document {
	static var nextId:Int = 1;
	public final id:Int;
	public var path(default, null):Null<String>;
	public var title(get, never):String;
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
	var highlighterSubscription:Null<BufferSubscription>;

	public function new(path:Null<String>, text:String, registry:SyntaxRegistry, ?fileSystem:EditorFileSystem) {
		id = nextId++;
		this.path = path;
		this.syntaxes = registry;
		this.fileSystem = fileSystem == null ? new FileSystemService() : fileSystem;
		buffer = new TextBuffer(text);
		diskContent = text;
		selectSyntax();
		savedStateId = buffer.stateId;
	}

	public static function untitled(registry:SyntaxRegistry, ?fileSystem:EditorFileSystem):Document
		return new Document(null, "", registry, fileSystem);

	function get_title():String
		return path == null ? "Untitled-" + id : fileName(path);

	public function hasBackingPath():Bool
		return path != null;

	public function requirePath():String {
		if (path == null) throw "document has no backing path";
		return path;
	}

	function get_dirty():Bool
		return buffer.stateId != savedStateId;

	public function setPath(path:String):Void {
		this.path = path;
		selectSyntax();
	}

	function selectSyntax():Void {
		if (highlighterSubscription != null) highlighterSubscription.release();
		syntax = syntaxes.find(path == null ? title : path, buffer.text.substr(0, 128));
		highlighter = new Highlighter(buffer, syntax);
		highlighterSubscription = buffer.subscribe(highlighter.bufferChanged);
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

	public function insert(selection:BufferSelection, text:String):Void
		buffer.insert(selection, text);

	public function backspace(selection:BufferSelection):Void {
		buffer.deleteBackward(selection);
	}

	public function deleteForward(selection:BufferSelection):Void {
		buffer.deleteForward(selection);
	}

	public function undo(selection:BufferSelection):Void {
		buffer.undo(selection);
	}

	public function redo(selection:BufferSelection):Void {
		buffer.redo(selection);
	}

	public function save(force:Bool = false):Bool {
		if (!hasBackingPath()) return false;
		checkExternal();
		if (externalState != Current && !force) return false;
		var encoded = encode(buffer.text), target = requirePath();
		if (!fileSystem.writeAtomic(target, encoded)) return false;
		savedStateId = buffer.stateId;
		diskContent = encoded;
		externalState = Current;
		return true;
	}

	public function saveAs(path:String):Bool {
		if (path.length == 0) return false;
		var encoded = encode(buffer.text);
		if (!fileSystem.writeAtomic(path, encoded)) return false;
		setPath(path);
		savedStateId = buffer.stateId;
		diskContent = encoded;
		externalState = Current;
		return true;
	}

	public function checkExternal():ExternalState {
		if (!hasBackingPath()) {
			externalState = Current;
			return externalState;
		}
		var target = requirePath();
		if (!fileSystem.exists(target)) {
			externalState = Deleted;
			return externalState;
		}
		var content:String;
		try {
			content = fileSystem.read(target);
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

	static function fileName(path:String):String {
		var slash = path.lastIndexOf("/");
		return slash < 0 ? path : path.substring(slash + 1);
	}
}
