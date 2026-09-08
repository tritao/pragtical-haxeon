package syntax;

import editor.TextBuffer;
import editor.BufferChange;

class Highlighter {
	public final buffer:TextBuffer;
	public final syntax:SyntaxDefinition;
	final cache:Map<Int, HighlightedLine> = [];

	public function new(buffer:TextBuffer, syntax:SyntaxDefinition) {
		this.buffer = buffer;
		this.syntax = syntax;
	}

	public function invalidate(line:Int, removedLines:Int, insertedLines:Int):Void {
		var retained:Map<Int, HighlightedLine> = [], delta = insertedLines - removedLines;
		for (index => highlighted in cache)
			if (index < line) retained.set(index, highlighted);
			else if (index > line + removedLines) retained.set(index + delta, highlighted);
		var stale = [for (index in cache.keys()) index];
		for (index in stale) cache.remove(index);
		for (index => highlighted in retained) cache.set(index, highlighted);
	}

	public function bufferChanged(change:BufferChange):Void
		invalidate(change.start.line, change.removedLines, change.insertedLines);

	public function line(index:Int):HighlightedLine {
		var state = false;
		for (lineIndex in 0...index + 1) {
			var text = buffer.line(lineIndex), cached = cache.get(lineIndex);
			if (cached == null || cached.text != text || cached.stateBefore != state) {
				cached = tokenize(text, state);
				cache.set(lineIndex, cached);
			}
			state = cached.stateAfter;
		}
		return cache.get(index);
	}

	function tokenize(text:String, initialState:Bool):HighlightedLine {
		if (!syntax.highlighting) return new HighlightedLine(text, [new HighlightToken(HighlightToken.NORMAL, 0, text.length)], false, false);
		var tokens:Array<HighlightToken> = [], index = 0, inComment = initialState;
		while (index < text.length) {
			var start = index, kind = HighlightToken.NORMAL;
			if (inComment) {
				kind = HighlightToken.COMMENT;
				var close = text.indexOf(syntax.blockCommentEnd, index);
				if (close < 0) index = text.length;
				else {
					index = close + syntax.blockCommentEnd.length;
					inComment = false;
				}
			} else if (syntax.lineComment.length > 0 && startsAt(text, index, syntax.lineComment)) {
				kind = HighlightToken.COMMENT;
				index = text.length;
			} else if (syntax.blockCommentStart.length > 0 && startsAt(text, index, syntax.blockCommentStart)) {
				kind = HighlightToken.COMMENT;
				var close = text.indexOf(syntax.blockCommentEnd, index + syntax.blockCommentStart.length);
				if (close < 0) {
					index = text.length;
					inComment = true;
				} else index = close + syntax.blockCommentEnd.length;
			} else {
				var code = text.charCodeAt(index);
				if (code == 34 || code == 39) {
					kind = HighlightToken.STRING;
					var quote = code;
					index++;
					while (index < text.length) {
						var current = text.charCodeAt(index++);
						if (current == 92 && index < text.length) index++;
						else if (current == quote) break;
					}
				} else if (isDigit(code)) {
					kind = HighlightToken.NUMBER;
					index++;
					while (index < text.length && (isIdentifier(text.charCodeAt(index)) || text.charCodeAt(index) == 46)) index++;
				} else if (isIdentifierStart(code)) {
					index++;
					while (index < text.length && isIdentifier(text.charCodeAt(index))) index++;
					var symbol = text.substring(start, index), symbolKind = syntax.keywords.get(symbol);
					kind = symbolKind == null ? HighlightToken.NORMAL : symbolKind;
				} else {
					kind = isSpace(code) ? HighlightToken.NORMAL : HighlightToken.OPERATOR;
					index++;
					while (index < text.length && isSpace(code) == isSpace(text.charCodeAt(index)) && (kind == HighlightToken.NORMAL
						|| !isIdentifierStart(text.charCodeAt(index)) && !isDigit(text.charCodeAt(index)))) index++;
				}
			}
			push(tokens, kind, start, index - start);
		}
		return new HighlightedLine(text, tokens, initialState, inComment);
	}

	static function push(tokens:Array<HighlightToken>, kind:Int, start:Int, length:Int):Void {
		if (length > 0) tokens.push(new HighlightToken(kind, start, length));
	}

	static function startsAt(text:String, index:Int, value:String):Bool
		return text.substr(index, value.length) == value;

	static function isSpace(code:Int):Bool
		return code == 9 || code == 32;

	static function isDigit(code:Int):Bool
		return code >= 48 && code <= 57;

	static function isIdentifierStart(code:Int):Bool
		return code == 95 || code >= 65 && code <= 90 || code >= 97 && code <= 122;

	static function isIdentifier(code:Int):Bool
		return isIdentifierStart(code) || isDigit(code);
}
