package search;

import editor.Document;

/** One compiled search query, reusable across every file in a workspace job. */
class SearchPattern {
	final query:String;
	final options:SearchOptions;
	final expression:Null<EReg>;

	public function new(query:String, options:SearchOptions) {
		this.query = query;
		this.options = options.copy();
		expression = options.regularExpression ? new EReg(query, options.caseSensitive ? "g" : "gi") : null;
	}

	public function findText(path:String, text:String, ?document:Document, revision:Int = -1):Array<SearchMatch> {
		var result:Array<SearchMatch> = [];
		if (query.length == 0) return result;
		var lines = text.split("\n");
		for (lineIndex in 0...lines.length)
			if (expression == null)
				findLiteral(path, lines[lineIndex], lineIndex, document, revision, result);
			else
				findRegularExpression(path, lines[lineIndex], lineIndex, expression, document, revision, result);
		return result;
	}

	function findLiteral(path:String, line:String, lineIndex:Int, document:Null<Document>, revision:Int, result:Array<SearchMatch>):Void {
		var needle = options.caseSensitive ? query : query.toLowerCase(), haystack = options.caseSensitive ? line : line.toLowerCase(), from = 0;
		while (from <= haystack.length - needle.length) {
			var column = haystack.indexOf(needle, from);
			if (column < 0) break;
			if (!options.wholeWord || isBoundary(line, column - 1) && isBoundary(line, column + query.length)) {
				var matched = line.substring(column, column + query.length);
				result.push(new SearchMatch(path, lineIndex, column, query.length, StringTools.trim(line), matched, document, revision, [matched]));
			}
			from = column + needle.length;
		}
	}

	function findRegularExpression(path:String, line:String, lineIndex:Int, expression:EReg, document:Null<Document>, revision:Int,
			result:Array<SearchMatch>):Void {
		var from = 0;
		while (from <= line.length && expression.matchSub(line, from)) {
			var position = expression.matchedPos(), column = position.pos, length = position.len;
			if (!options.wholeWord || isBoundary(line, column - 1) && isBoundary(line, column + length)) {
				var captures = [for (index in 0...expression.matchedNum()) expression.matched(index)], matched = expression.matched(0);
				result.push(new SearchMatch(path, lineIndex, column, length, StringTools.trim(line), matched, document, revision, captures, true));
			}
			var next = column + length;
			if (length == 0) {
				if (next >= line.length) break;
				next = nextScalarOffset(line, next);
			}
			from = next;
		}
	}

	static function isBoundary(value:String, index:Int):Bool {
		if (index < 0 || index >= value.length) return true;
		var code = value.charCodeAt(index);
		return !(code >= 48 && code <= 57 || code >= 65 && code <= 90 || code >= 97 && code <= 122 || code == 95 || code >= 128);
	}

	static function nextScalarOffset(value:String, offset:Int):Int {
		var first = value.charCodeAt(offset);
		return first >= 0xD800 && first <= 0xDBFF && offset + 1 < value.length
			&& value.charCodeAt(offset + 1) >= 0xDC00 && value.charCodeAt(offset + 1) <= 0xDFFF ? offset + 2 : offset + 1;
	}
}
