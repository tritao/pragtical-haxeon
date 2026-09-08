package search;

class ReplacementPreview {
	public final searchGeneration:Int;
	public final query:String;
	public final replacement:String;
	public final files:Array<ReplacementFilePreview>;
	public final matchCount:Int;
	public var applied(default, null):Bool = false;

	public function new(searchGeneration:Int, query:String, replacement:String, files:Array<ReplacementFilePreview>, matchCount:Int) {
		this.searchGeneration = searchGeneration;
		this.query = query;
		this.replacement = replacement;
		this.files = files;
		this.matchCount = matchCount;
	}

	public function markApplied():Void applied = true;
}
