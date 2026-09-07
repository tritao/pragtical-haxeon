package core;

import editor.Document;
import syntax.SyntaxRegistry;

class DocumentManager {
	public final documents:Array<Document> = [];
	public final syntaxes:SyntaxRegistry;

	public function new(syntaxes:SyntaxRegistry) {
		this.syntaxes = syntaxes;
	}

	public function open(path:String):Document {
		for (document in documents)
			if (document.path == path)
				return document;
		var document = Document.open(path, syntaxes);
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
