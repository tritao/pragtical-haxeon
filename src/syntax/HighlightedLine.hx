package syntax;

class HighlightedLine {
	public final text:String;
	public final tokens:Array<HighlightToken>;
	public final stateBefore:Int;
	public final stateAfter:Int;

	public function new(text:String, tokens:Array<HighlightToken>, stateBefore:Int, stateAfter:Int) {
		this.text = text;
		this.tokens = tokens;
		this.stateBefore = stateBefore;
		this.stateAfter = stateAfter;
	}
}
