package search;

import editor.Document;

class ReplacementFilePreview {
	public final path:String;
	public final originalText:String;
	public final proposedText:String;
	public final matchCount:Int;
	public final document:Null<Document>;
	public final revision:Int;

	public function new(path:String, originalText:String, proposedText:String, matchCount:Int, ?document:Document, revision:Int = -1) {
		this.path = path;
		this.originalText = originalText;
		this.proposedText = proposedText;
		this.matchCount = matchCount;
		this.document = document;
		this.revision = revision;
	}
}
