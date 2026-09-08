package search;

class SearchOptions {
	public var caseSensitive:Bool;
	public var wholeWord:Bool;
	public var regularExpression:Bool = false;
	public var pathFilter:String = "";

	public function new(caseSensitive:Bool = false, wholeWord:Bool = false) {
		this.caseSensitive = caseSensitive;
		this.wholeWord = wholeWord;
	}

	public function copy():SearchOptions {
		var result = new SearchOptions(caseSensitive, wholeWord);
		result.regularExpression = regularExpression;
		result.pathFilter = pathFilter;
		return result;
	}
}
