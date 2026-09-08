package core;

import editor.Document;
import syntax.SyntaxRegistry;
import workspace.FileSystemService;
import workspace.EditorFileSystem;

class DocumentManager {
	public final documents:Array<Document> = [];
	public final syntaxes:SyntaxRegistry;
	public final fileSystem:EditorFileSystem;

	public function new(syntaxes:SyntaxRegistry, ?fileSystem:EditorFileSystem) {
		this.syntaxes = syntaxes;
		this.fileSystem = fileSystem == null ? new FileSystemService() : fileSystem;
	}

	public function open(path:String):Document {
		for (document in documents)
			if (document.path == path)
				return document;
		var normalized = fileSystem.normalize(path);
		for (document in documents)
			if (document.path == normalized) return document;
		var document = Document.open(normalized, syntaxes, fileSystem);
		documents.push(document);
		return document;
	}

	public function createUntitled():Document {
		var document = Document.untitled(syntaxes, fileSystem);
		documents.push(document);
		return document;
	}

	public function saveAs(document:Document, destination:String, overwrite:Bool = false):Bool {
		try {
			var normalized = fileSystem.normalize(destination);
			for (existing in documents)
				if (existing != document && existing.path.length > 0 && existing.path == normalized) return false;
			if (fileSystem.exists(normalized) && !overwrite) return false;
			return document.saveAs(normalized);
		} catch (error:Dynamic) {
			return false;
		}
	}

	public function rename(document:Document, destination:String):Bool {
		if (!document.hasBackingPath()) return false;
		var normalized = fileSystem.normalize(destination);
		for (existing in documents) if (existing != document && existing.path == normalized) return false;
		if (!fileSystem.rename(document.path, normalized)) return false;
		document.setPath(normalized);
		return true;
	}

	public function checkExternalChanges():Void
		for (document in documents) document.checkExternal();

	public function add(document:Document):Document {
		for (existing in documents)
			if (existing == document || document.hasBackingPath() && existing.path == document.path)
				return existing;
		documents.push(document);
		return document;
	}

	public function close(document:Document, force:Bool = false):Bool {
		if (document.dirty && !force)
			return false;
		return documents.remove(document);
	}
}
