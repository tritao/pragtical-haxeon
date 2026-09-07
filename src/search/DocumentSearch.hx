package search;

import editor.BufferPosition;
import editor.Document;

class DocumentSearch {
	public static function find(document:Document, query:String, options:SearchOptions):Array<SearchMatch>
		return findText(document.path, document.buffer.text, query, options);

	public static function findText(path:String, text:String, query:String, options:SearchOptions):Array<SearchMatch> {
		var result:Array<SearchMatch> = [];
		if (query.length == 0) return result;
		var needle = options.caseSensitive ? query : query.toLowerCase(), lines = text.split("\n");
		for (lineIndex in 0...lines.length) {
			var line = lines[lineIndex], haystack = options.caseSensitive ? line : line.toLowerCase(), from = 0;
			while (from <= haystack.length - needle.length) {
				var column = haystack.indexOf(needle, from);
				if (column < 0) break;
				if (!options.wholeWord || isBoundary(line, column - 1) && isBoundary(line, column + query.length))
					result.push(new SearchMatch(path, lineIndex, column, query.length, StringTools.trim(line)));
				from = column + (needle.length == 0 ? 1 : needle.length);
			}
		}
		return result;
	}

	public static function select(document:Document, match:SearchMatch):Void {
		var start = new BufferPosition(match.line, match.column), end = new BufferPosition(match.line, match.column + match.length);
		document.buffer.setCursor(start);
		document.buffer.setCursor(end, true);
	}

	public static function replaceCurrent(document:Document, match:SearchMatch, replacement:String):Bool
		return document.buffer.replaceRange(new BufferPosition(match.line, match.column), new BufferPosition(match.line, match.column + match.length), replacement);

	public static function replaceAll(document:Document, query:String, replacement:String, options:SearchOptions):Int {
		var matches = find(document, query, options);
		if (matches.length == 0) return 0;
		var text = document.buffer.text;
		for (index in 0...matches.length) {
			var match = matches[matches.length - index - 1], start = document.buffer.offsetOf(new BufferPosition(match.line, match.column));
			text = text.substring(0, start) + replacement + text.substring(start + match.length);
		}
		document.buffer.replaceAllText(text);
		return matches.length;
	}

	static function isBoundary(value:String, index:Int):Bool {
		if (index < 0 || index >= value.length) return true;
		var code = value.charCodeAt(index);
		return !codePointWord(code);
	}

	static function codePointWord(code:Int):Bool
		return code >= 48 && code <= 57 || code >= 65 && code <= 90 || code >= 97 && code <= 122 || code == 95 || code >= 128;
}
