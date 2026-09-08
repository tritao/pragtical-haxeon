package search;

import editor.BufferPosition;
import editor.Document;
import editor.BufferSelection;

class DocumentSearch {
	public static function find(document:Document, query:String, options:SearchOptions):Array<SearchMatch>
		return findText(document.path == null ? document.title : document.path, document.buffer.text, query, options, document, document.buffer.stateId);

	public static function findText(path:String, text:String, query:String, options:SearchOptions, ?document:Document, revision:Int = -1):Array<SearchMatch> {
		return new SearchPattern(query, options).findText(path, text, document, revision);
	}

	public static function select(document:Document, selection:BufferSelection, match:SearchMatch):Bool {
		if (!valid(document, match)) return false;
		var start = new BufferPosition(match.line, match.column), end = new BufferPosition(match.line, match.column + match.length);
		selection.restore(document.buffer, end, start);
		return true;
	}

	public static function replaceCurrent(document:Document, selection:BufferSelection, match:SearchMatch, replacement:String):Bool
		return valid(document, match)
			&& document.buffer.replaceRange(selection, new BufferPosition(match.line, match.column),
				new BufferPosition(match.line, match.column + match.length), replacementFor(match, replacement));

	public static function replaceAll(document:Document, selection:BufferSelection, query:String, replacement:String, options:SearchOptions):Int {
		var matches = find(document, query, options);
		if (matches.length == 0) return 0;
		var text = document.buffer.text;
		for (index in 0...matches.length) {
			var match = matches[matches.length - index - 1], start = document.buffer.offsetOf(new BufferPosition(match.line, match.column));
			text = text.substring(0, start) + replacementFor(match, replacement) + text.substring(start + match.length);
		}
		document.buffer.replaceAllText(text, selection);
		return matches.length;
	}

	public static function valid(document:Document, match:SearchMatch):Bool {
		if (match.document != null && (match.document != document || match.revision != document.buffer.stateId)) return false;
		if (match.document == null && (document.path == null || match.path != document.path)) return false;
		var from = new BufferPosition(match.line, match.column), to = new BufferPosition(match.line, match.column + match.length);
		return document.buffer.textRange(from, to) == match.matchedText;
	}

	public static function replacementFor(match:SearchMatch, replacement:String):String {
		if (!match.regularExpression) return replacement;
		var output = new StringBuf(), index = 0;
		while (index < replacement.length) {
			if (replacement.charAt(index) != "$" || index + 1 >= replacement.length) {
				output.add(replacement.charAt(index++));
				continue;
			}
			var code = replacement.charCodeAt(index + 1);
			if (code == 36) output.add("$"); else if (code >= 49 && code <= 57 && code - 48 < match.captures.length)
				output.add(match.captures[code - 48]); else output.add("$" + replacement.charAt(index + 1));
			index += 2;
		}
		return output.toString();
	}
}
