package syntax;

class SyntaxDefinition {
	public final name:String;
	public final extensions:Array<String>;
	public final headers:Array<String>;
	public final keywords:Map<String, Int>;
	public final highlighting:Bool;
	public final lineComment:String;
	public final blockCommentStart:String;
	public final blockCommentEnd:String;

	public function new(name:String, extensions:Array<String>, highlighting:Bool, ?keywords:Map<String, Int>, ?headers:Array<String>, lineComment:String = "//",
			blockCommentStart:String = "/*", blockCommentEnd:String = "*/") {
		this.name = name;
		this.extensions = extensions;
		this.headers = headers == null ? [] : headers;
		this.highlighting = highlighting;
		this.keywords = keywords == null ? [] : keywords;
		this.lineComment = lineComment;
		this.blockCommentStart = blockCommentStart;
		this.blockCommentEnd = blockCommentEnd;
	}
}
