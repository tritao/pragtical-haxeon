package editor;

import syntax.SyntaxDefinition;

class EditorActions {
	public static function indent(buffer:TextBuffer, selection:BufferSelection, tabWidth:Int, insertSpaces:Bool):Bool {
		var span = selectedLines(selection), unit = indentationUnit(tabWidth, insertSpaces), replacements:Array<BufferReplacement> = [],
			changes:Map<Int, LineColumnChange> = [];
		for (line in span.first...span.last + 1) {
			replacements.push(new BufferReplacement(new BufferPosition(line, 0), new BufferPosition(line, 0), unit));
			changes.set(line, new LineColumnChange(0, unit.length));
		}
		return apply(buffer, selection, replacements, changes);
	}

	public static function unindent(buffer:TextBuffer, selection:BufferSelection, tabWidth:Int):Bool {
		var span = selectedLines(selection), replacements:Array<BufferReplacement> = [], changes:Map<Int, LineColumnChange> = [];
		for (line in span.first...span.last + 1) {
			var text = buffer.line(line), count = 0;
			if (text.length > 0 && text.charCodeAt(0) == 9) count = 1;
			else while (count < tabWidth && count < text.length && text.charCodeAt(count) == 32) count++;
			if (count > 0) {
				replacements.push(new BufferReplacement(new BufferPosition(line, 0), new BufferPosition(line, count), ""));
				changes.set(line, new LineColumnChange(0, -count));
			}
		}
		return apply(buffer, selection, replacements, changes);
	}

	public static function insertNewline(buffer:TextBuffer, selection:BufferSelection):Bool {
		var line = buffer.line(selection.start().line), indentation = line.substring(0, leadingWhitespace(line));
		return buffer.insert(selection, "\n" + indentation);
	}

	public static function duplicateLines(buffer:TextBuffer, selection:BufferSelection):Bool {
		var span = selectedLines(selection), block = lineBlock(buffer, span.first, span.last), count = span.last - span.first + 1,
			at:BufferPosition, text:String;
		if (span.last + 1 < buffer.lineCount()) {
			at = new BufferPosition(span.last + 1, 0);
			text = block + "\n";
		} else {
			at = buffer.endPosition();
			text = "\n" + block;
		}
		var cursor = shiftedLine(selection.cursor, count), anchor = shiftedLine(selection.anchor, count);
		return buffer.applyReplacements(selection, [new BufferReplacement(at, at, text)], cursor, anchor);
	}

	public static function deleteLines(buffer:TextBuffer, selection:BufferSelection):Bool {
		var span = selectedLines(selection), from:BufferPosition, to:BufferPosition, result:BufferPosition;
		if (span.last + 1 < buffer.lineCount()) {
			from = new BufferPosition(span.first, 0);
			to = new BufferPosition(span.last + 1, 0);
			result = from;
		} else if (span.first > 0) {
			from = new BufferPosition(span.first - 1, buffer.line(span.first - 1).length);
			to = buffer.endPosition();
			result = from;
		} else {
			from = new BufferPosition(0, 0);
			to = buffer.endPosition();
			result = from;
		}
		return buffer.applyReplacements(selection, [new BufferReplacement(from, to, "")], result, result);
	}

	public static function moveLines(buffer:TextBuffer, selection:BufferSelection, direction:Int):Bool {
		var span = selectedLines(selection), from:BufferPosition, to:BufferPosition, replacement:String;
		if (direction < 0) {
			if (span.first == 0) return false;
			from = new BufferPosition(span.first - 1, 0);
			to = span.last + 1 < buffer.lineCount() ? new BufferPosition(span.last + 1, 0) : buffer.endPosition();
			replacement = lineBlock(buffer, span.first, span.last) + "\n" + buffer.line(span.first - 1)
				+ (span.last + 1 < buffer.lineCount() ? "\n" : "");
		} else {
			if (span.last + 1 >= buffer.lineCount()) return false;
			from = new BufferPosition(span.first, 0);
			to = span.last + 2 < buffer.lineCount() ? new BufferPosition(span.last + 2, 0) : buffer.endPosition();
			replacement = buffer.line(span.last + 1) + "\n" + lineBlock(buffer, span.first, span.last)
				+ (span.last + 2 < buffer.lineCount() ? "\n" : "");
		}
		var cursor = shiftedLine(selection.cursor, direction), anchor = shiftedLine(selection.anchor, direction);
		return buffer.applyReplacements(selection, [new BufferReplacement(from, to, replacement)], cursor, anchor);
	}

	public static function joinLines(buffer:TextBuffer, selection:BufferSelection):Bool {
		var span = selectedLines(selection), first = span.first, last = selection.hasSelection() ? span.last : span.first + 1;
		if (last >= buffer.lineCount()) last = buffer.lineCount() - 1;
		if (first >= last) return false;
		var replacements:Array<BufferReplacement> = [];
		for (line in first...last) {
			var left = buffer.line(line), right = buffer.line(line + 1), whitespace = leadingWhitespace(right), separator = " ";
			if (left.length == 0 || whitespace == right.length || isSpace(left.charCodeAt(left.length - 1))) separator = "";
			replacements.push(new BufferReplacement(new BufferPosition(line, left.length), new BufferPosition(line + 1, whitespace), separator));
		}
		var result = new BufferPosition(first, buffer.line(first).length + 1);
		return buffer.applyReplacements(selection, replacements, result, result);
	}

	public static function toggleLineComment(buffer:TextBuffer, selection:BufferSelection, syntax:SyntaxDefinition):Bool {
		var marker = syntax.lineComment;
		if (marker.length == 0) return false;
		var span = selectedLines(selection), uncomment = true;
		for (line in span.first...span.last + 1) {
			var text = buffer.line(line), column = leadingWhitespace(text);
			if (text.substr(column, marker.length) != marker) uncomment = false;
		}
		var replacements:Array<BufferReplacement> = [], changes:Map<Int, LineColumnChange> = [];
		for (line in span.first...span.last + 1) {
			var text = buffer.line(line), column = leadingWhitespace(text);
			if (uncomment) {
				var count = marker.length;
				if (text.substr(column + count, 1) == " ") count++;
				replacements.push(new BufferReplacement(new BufferPosition(line, column), new BufferPosition(line, column + count), ""));
				changes.set(line, new LineColumnChange(column, -count));
			} else {
				var inserted = marker + " ";
				replacements.push(new BufferReplacement(new BufferPosition(line, column), new BufferPosition(line, column), inserted));
				changes.set(line, new LineColumnChange(column, inserted.length));
			}
		}
		return apply(buffer, selection, replacements, changes);
	}

	static function apply(buffer:TextBuffer, selection:BufferSelection, replacements:Array<BufferReplacement>, changes:Map<Int, LineColumnChange>):Bool {
		if (replacements.length == 0) return false;
		return buffer.applyReplacements(selection, replacements, adjust(selection.cursor, changes), adjust(selection.anchor, changes));
	}

	static function adjust(position:BufferPosition, changes:Map<Int, LineColumnChange>):BufferPosition {
		var change = changes.get(position.line);
		if (change == null || position.column <= change.column) return position;
		var column = position.column + change.delta;
		if (column < change.column) column = change.column;
		return new BufferPosition(position.line, column);
	}

	static function selectedLines(selection:BufferSelection):EditorLineSpan {
		var first = selection.start().line, last = selection.end().line;
		if (selection.hasSelection() && selection.end().column == 0 && last > first) last--;
		return new EditorLineSpan(first, last);
	}

	static function lineBlock(buffer:TextBuffer, first:Int, last:Int):String {
		var lines:Array<String> = [];
		for (line in first...last + 1) lines.push(buffer.line(line));
		return lines.join("\n");
	}

	static function leadingWhitespace(text:String):Int {
		var result = 0;
		while (result < text.length && isSpace(text.charCodeAt(result))) result++;
		return result;
	}

	static function indentationUnit(tabWidth:Int, insertSpaces:Bool):String {
		if (!insertSpaces) return "\t";
		var result = "";
		for (index in 0...tabWidth) result += " ";
		return result;
	}

	static function shiftedLine(position:BufferPosition, delta:Int):BufferPosition
		return new BufferPosition(position.line + delta, position.column);

	static function isSpace(code:Int):Bool return code == 9 || code == 32;
}

private class EditorLineSpan {
	public final first:Int;
	public final last:Int;
	public function new(first:Int, last:Int) {
		this.first = first;
		this.last = last;
	}
}

private class LineColumnChange {
	public final column:Int;
	public final delta:Int;
	public function new(column:Int, delta:Int) {
		this.column = column;
		this.delta = delta;
	}
}
