package editor;

class TextBuffer {
	public var onChange:Null<(line:Int, removedLines:Int, insertedLines:Int) -> Void>;
	final lines:Array<String>;
	public var cursor(default, null):BufferPosition;
	public var anchor(default, null):BufferPosition;
	public var stateId(default, null):Int = 0;
	var nextStateId:Int = 1;
	var preferredColumn:Int = -1;
	final undoStack:Array<BufferEdit> = [];
	final redoStack:Array<BufferEdit> = [];
	public var text(get, never):String;

	public function new(?text:String) {
		lines = splitLines(text == null ? "" : text);
		cursor = new BufferPosition(0, 0);
		anchor = cursor;
	}

	function get_text():String
		return lines.join("\n");

	public function lineCount():Int
		return lines.length;

	public function line(index:Int):String
		return index < 0 || index >= lines.length ? "" : lines[index];

	public function hasSelection():Bool
		return !cursor.equals(anchor);

	public function selectionStart():BufferPosition
		return cursor.before(anchor) ? cursor : anchor;

	public function selectionEnd():BufferPosition
		return cursor.before(anchor) ? anchor : cursor;

	public function setCursor(position:BufferPosition, extend:Bool = false):Void {
		cursor = sanitize(position);
		if (!extend) anchor = cursor;
		preferredColumn = -1;
	}

	public function move(delta:Int, extend:Bool = false):Void
		setCursor(positionOffset(cursor, delta), extend);

	public function selectAll():Void {
		anchor = new BufferPosition(0, 0);
		cursor = documentEnd();
		preferredColumn = -1;
	}

	public function selectedText():String
		return hasSelection() ? textRange(selectionStart(), selectionEnd()) : "";

	public function insert(value:String):Bool {
		if (value.length == 0 && !hasSelection()) return false;
		return replace(selectionStart(), selectionEnd(), value);
	}

	public function deleteBackward():Bool {
		if (hasSelection()) return replace(selectionStart(), selectionEnd(), "");
		var start = positionOffset(cursor, -1);
		return start.equals(cursor) ? false : replace(start, cursor, "");
	}

	public function deleteForward():Bool {
		if (hasSelection()) return replace(selectionStart(), selectionEnd(), "");
		var end = positionOffset(cursor, 1);
		return end.equals(cursor) ? false : replace(cursor, end, "");
	}

	public function undo():Bool {
		var edit = undoStack.pop();
		if (edit == null) return false;
		replaceRaw(edit.start, advance(edit.start, edit.inserted), edit.removed);
		cursor = edit.cursorBefore;
		anchor = edit.anchorBefore;
		stateId = edit.stateBefore;
		preferredColumn = -1;
		redoStack.push(edit);
		return true;
	}

	public function redo():Bool {
		var edit = redoStack.pop();
		if (edit == null) return false;
		replaceRaw(edit.start, advance(edit.start, edit.removed), edit.inserted);
		cursor = edit.cursorAfter;
		anchor = edit.anchorAfter;
		stateId = edit.stateAfter;
		preferredColumn = -1;
		undoStack.push(edit);
		return true;
	}

	public function moveHome(extend:Bool = false):Void
		setCursor(new BufferPosition(cursor.line, 0), extend);

	public function moveEnd(extend:Bool = false):Void
		setCursor(new BufferPosition(cursor.line, line(cursor.line).length), extend);

	public function moveVertical(delta:Int, extend:Bool = false):Void {
		if (preferredColumn < 0) preferredColumn = cursor.column;
		var targetLine = cursor.line + delta;
		if (targetLine < 0) targetLine = 0;
		else if (targetLine >= lines.length) targetLine = lines.length - 1;
		var column = preferredColumn > lines[targetLine].length ? lines[targetLine].length : preferredColumn;
		cursor = new BufferPosition(targetLine, column);
		if (!extend) anchor = cursor;
	}

	public function positionAt(line:Int, column:Int):BufferPosition
		return sanitize(new BufferPosition(line, column));

	public function positionOffset(position:BufferPosition, offset:Int):BufferPosition {
		var result = sanitize(position), remaining = offset;
		while (remaining < 0) {
			if (result.column > 0) {
				var column = result.column - 1;
				if (column > 0 && isLowSurrogate(lines[result.line].charCodeAt(column))
					&& isHighSurrogate(lines[result.line].charCodeAt(column - 1))) column--;
				result = new BufferPosition(result.line, column);
				remaining++;
			} else if (result.line > 0) {
				result = new BufferPosition(result.line - 1, lines[result.line - 1].length);
				remaining++;
			} else break;
		}
		while (remaining > 0) {
			var value = lines[result.line];
			if (result.column < value.length) {
				var column = result.column + 1;
				if (column < value.length && isHighSurrogate(value.charCodeAt(result.column))
					&& isLowSurrogate(value.charCodeAt(column))) column++;
				result = new BufferPosition(result.line, column);
				remaining--;
			} else if (result.line + 1 < lines.length) {
				result = new BufferPosition(result.line + 1, 0);
				remaining--;
			} else break;
		}
		return result;
	}

	public function textRange(from:BufferPosition, to:BufferPosition):String {
		var start = sanitize(from), end = sanitize(to);
		if (end.before(start)) {
			var swap = start;
			start = end;
			end = swap;
		}
		if (start.line == end.line) return lines[start.line].substring(start.column, end.column);
		var parts = [lines[start.line].substring(start.column)];
		for (lineIndex in start.line + 1...end.line) parts.push(lines[lineIndex]);
		parts.push(lines[end.line].substring(0, end.column));
		return parts.join("\n");
	}

	public function offsetOf(position:BufferPosition):Int {
		var value = sanitize(position), offset = value.column;
		for (lineIndex in 0...value.line) offset += lines[lineIndex].length + 1;
		return offset;
	}

	public function positionFromOffset(offset:Int):BufferPosition {
		var remaining = offset < 0 ? 0 : offset;
		for (lineIndex in 0...lines.length) {
			if (remaining <= lines[lineIndex].length) return new BufferPosition(lineIndex, remaining);
			remaining -= lines[lineIndex].length + 1;
		}
		return documentEnd();
	}

	function replace(from:BufferPosition, to:BufferPosition, value:String):Bool {
		var start = sanitize(from), end = sanitize(to);
		if (end.before(start)) {
			var swap = start;
			start = end;
			end = swap;
		}
		var removed = textRange(start, end), beforeCursor = cursor, beforeAnchor = anchor, beforeState = stateId;
		if (removed == value) return false;
		replaceRaw(start, end, value);
		cursor = advance(start, value);
		anchor = cursor;
		preferredColumn = -1;
		stateId = nextStateId++;
		undoStack.push(new BufferEdit(start, removed, value, beforeCursor, beforeAnchor, cursor, anchor, beforeState, stateId));
		redoStack.resize(0);
		return true;
	}

	function replaceRaw(from:BufferPosition, to:BufferPosition, value:String):Void {
		var replacement = splitLines(value), prefix = lines[from.line].substring(0, from.column), suffix = lines[to.line].substring(to.column);
		replacement[0] = prefix + replacement[0];
		replacement[replacement.length - 1] += suffix;
		lines.splice(from.line, to.line - from.line + 1);
		for (index in 0...replacement.length) lines.insert(from.line + index, replacement[index]);
		if (onChange != null) onChange(from.line, to.line - from.line, replacement.length - 1);
	}

	function advance(start:BufferPosition, value:String):BufferPosition {
		var inserted = splitLines(value);
		return inserted.length == 1 ? new BufferPosition(start.line, start.column + inserted[0].length) :
			new BufferPosition(start.line + inserted.length - 1, inserted[inserted.length - 1].length);
	}

	function sanitize(position:BufferPosition):BufferPosition {
		var line = position.line < 0 ? 0 : position.line >= lines.length ? lines.length - 1 : position.line,
			column = position.column < 0 ? 0 : position.column > lines[line].length ? lines[line].length : position.column;
		return new BufferPosition(line, column);
	}

	function documentEnd():BufferPosition
		return new BufferPosition(lines.length - 1, lines[lines.length - 1].length);

	static function splitLines(value:String):Array<String> {
		var result = value.split("\n");
		return result.length == 0 ? [""] : result;
	}

	static function isHighSurrogate(code:Int):Bool
		return code >= 0xD800 && code <= 0xDBFF;

	static function isLowSurrogate(code:Int):Bool
		return code >= 0xDC00 && code <= 0xDFFF;
}
