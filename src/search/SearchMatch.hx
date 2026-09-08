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
	public final captures:Array<String>;
	public final regularExpression:Bool;

	public function new(path:String, line:Int, column:Int, length:Int, preview:String, matchedText:String, ?document:Document, revision:Int = -1,
			?captures:Array<String>, regularExpression:Bool = false) {
		this.path = path;
		this.line = line;
		this.column = column;
		this.length = length;
		this.preview = preview;
		this.matchedText = matchedText;
		this.document = document;
		this.revision = revision;
		this.captures = captures == null ? [] : captures;
		this.regularExpression = regularExpression;
	}
}
