package syntax;

class HighlightedLine {
	public final text:String;
	public final tokens:Array<HighlightToken>;
	public final stateBefore:Bool;
	public final stateAfter:Bool;

	public function new(text:String, tokens:Array<HighlightToken>, stateBefore:Bool, stateAfter:Bool) {
		this.text = text;
		this.tokens = tokens;
		this.stateBefore = stateBefore;
		this.stateAfter = stateAfter;
	}
}
