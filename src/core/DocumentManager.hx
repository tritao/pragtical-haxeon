package core;

import editor.Document;

class DocumentManager {
	public final documents:Array<Document> = [];

	public function new() {}

	public function open(path:String):Document {
		for (document in documents)
			if (document.path == path)
				return document;
		var document = Document.open(path);
		documents.push(document);
		return document;
	}

	public function add(document:Document):Document {
		for (existing in documents)
			if (existing == document || existing.path == document.path)
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
