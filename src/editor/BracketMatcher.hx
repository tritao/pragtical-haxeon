package editor;

import syntax.Highlighter;
import syntax.HighlightToken;

class BracketMatcher {
	static inline final MAX_SCAN = 100000;

	public static function find(buffer:TextBuffer, highlighter:Highlighter, caret:BufferPosition):Null<BracketPair> {
		var candidate = bracketAt(buffer, highlighter, caret);
		if (candidate == null && caret.column > 0)
			candidate = bracketAt(buffer, highlighter, new BufferPosition(caret.line, caret.column - 1));
		if (candidate == null) return null;
		var opening = openingFor(candidate.code), closing = closingFor(candidate.code), direction = isOpening(candidate.code) ? 1 : -1,
			depth = 1, scanned = 0, line = candidate.position.line, column = candidate.position.column;
		while (line >= 0 && line < buffer.lineCount() && scanned < MAX_SCAN) {
			var text = buffer.line(line);
			column += direction;
			while (column >= 0 && column < text.length && scanned < MAX_SCAN) {
				if (codeKind(highlighter, line, column)) {
					var code = text.charCodeAt(column);
					if (direction > 0 && code == opening || direction < 0 && code == closing) depth++;
					else if (direction > 0 && code == closing || direction < 0 && code == opening) {
						depth--;
						if (depth == 0) {
							var found = new BufferPosition(line, column);
							return direction > 0 ? new BracketPair(candidate.position, found) : new BracketPair(found, candidate.position);
						}
					}
				}
				column += direction;
				scanned++;
			}
			line += direction;
			if (line >= 0 && line < buffer.lineCount()) column = direction > 0 ? -1 : buffer.line(line).length;
		}
		return null;
	}

	static function bracketAt(buffer:TextBuffer, highlighter:Highlighter, position:BufferPosition):Null<{position:BufferPosition, code:Int}> {
		var text = buffer.line(position.line);
		if (position.column < 0 || position.column >= text.length) return null;
		var code = text.charCodeAt(position.column);
		return (isOpening(code) || isClosing(code)) && codeKind(highlighter, position.line, position.column)
			? {position: position, code: code} : null;
	}

	static function codeKind(highlighter:Highlighter, line:Int, column:Int):Bool {
		for (token in highlighter.line(line).tokens)
			if (column >= token.start && column < token.start + token.length)
				return token.kind != HighlightToken.STRING && token.kind != HighlightToken.COMMENT;
		return true;
	}

	static function isOpening(code:Int):Bool return code == 40 || code == 91 || code == 123;
	static function isClosing(code:Int):Bool return code == 41 || code == 93 || code == 125;
	static function openingFor(code:Int):Int return code == 41 ? 40 : code == 93 ? 91 : code == 125 ? 123 : code;
	static function closingFor(code:Int):Int return code == 40 ? 41 : code == 91 ? 93 : code == 123 ? 125 : code;
}
