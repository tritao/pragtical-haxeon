package search;

import editor.Document;

class SearchMatch {
	public final path:String;
	public final line:Int;
	public final column:Int;
	public final length:Int;
	public final preview:String;
	public final matchedText:String;
	public final document:Null<Document>;
	public final revision:Int;

	public function new(path:String, line:Int, column:Int, length:Int, preview:String, matchedText:String, ?document:Document, revision:Int = -1) {
		this.path = path;
		this.line = line;
		this.column = column;
		this.length = length;
		this.preview = preview;
		this.matchedText = matchedText;
		this.document = document;
		this.revision = revision;
	}
}
