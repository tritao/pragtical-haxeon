package completion;

import editor.BufferPosition;
import editor.Document;

class CompletionRequest {
	public final document:Document;
	public final position:BufferPosition;
	public final replaceFrom:BufferPosition;
	public final prefix:String;

	public function new(document:Document, position:BufferPosition, replaceFrom:BufferPosition, prefix:String) {
		this.document = document;
		this.position = position;
		this.replaceFrom = replaceFrom;
		this.prefix = prefix;
	}
}
