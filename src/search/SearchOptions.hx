package search;

class SearchOptions {
	public var caseSensitive:Bool;
	public var wholeWord:Bool;

	public function new(caseSensitive:Bool = false, wholeWord:Bool = false) {
		this.caseSensitive = caseSensitive;
		this.wholeWord = wholeWord;
	}
}
