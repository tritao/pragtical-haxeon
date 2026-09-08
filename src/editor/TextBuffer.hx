package editor;

class TextBuffer {
	final lines:Array<String>;
	final changeListeners:Map<Int, BufferChangeListener> = [];
	var nextListenerId:Int = 1;
	public var stateId(default, null):Int = 0;
	var nextStateId:Int = 1;
	final undoStack:Array<BufferEdit> = [];
	final redoStack:Array<BufferEdit> = [];
	public var text(get, never):String;

	public function new(?text:String) {
		lines = splitLines(text == null ? "" : text);
	}

	function get_text():String
		return lines.join("\n");

	public function lineCount():Int
		return lines.length;

	public function line(index:Int):String
		return index < 0 || index >= lines.length ? "" : lines[index];

	/** Registers a listener and returns its idempotent owned subscription. */
	public function subscribe(listener:BufferChangeListener):BufferSubscription {
		var id = nextListenerId++;
		changeListeners.set(id, listener);
		return new BufferSubscription(this, id);
	}

	@:allow(editor.BufferSubscription)
	function releaseSubscription(id:Int):Void
		changeListeners.remove(id);

	public function insert(selection:BufferSelection, value:String):Bool {
		if (value.length == 0 && !selection.hasSelection()) return false;
		return replace(selection, selection.start(), selection.end(), value);
	}

	public function replaceRange(selection:BufferSelection, from:BufferPosition, to:BufferPosition, value:String):Bool
		return replace(selection, from, to, value);

	public function replaceAllText(value:String, ?selection:BufferSelection):Bool {
		var owner = selection == null ? new BufferSelection() : selection;
		return replace(owner, new BufferPosition(0, 0), endPosition(), value);
	}

	public function deleteBackward(selection:BufferSelection):Bool {
		if (selection.hasSelection()) return replace(selection, selection.start(), selection.end(), "");
		var start = positionOffset(selection.cursor, -1);
		return start.equals(selection.cursor) ? false : replace(selection, start, selection.cursor, "");
	}

	public function deleteForward(selection:BufferSelection):Bool {
		if (selection.hasSelection()) return replace(selection, selection.start(), selection.end(), "");
		var end = positionOffset(selection.cursor, 1);
		return end.equals(selection.cursor) ? false : replace(selection, selection.cursor, end, "");
	}

	public function undo(selection:BufferSelection):Bool {
		var edit = undoStack.pop();
		if (edit == null) return false;
		replaceRaw(edit.start, advance(edit.start, edit.inserted), edit.removed, edit.stateAfter, edit.stateBefore);
		selection.restore(this, edit.cursorBefore, edit.anchorBefore);
		stateId = edit.stateBefore;
		redoStack.push(edit);
		return true;
	}

	public function redo(selection:BufferSelection):Bool {
		var edit = redoStack.pop();
		if (edit == null) return false;
		replaceRaw(edit.start, advance(edit.start, edit.removed), edit.inserted, edit.stateBefore, edit.stateAfter);
		selection.restore(this, edit.cursorAfter, edit.anchorAfter);
		stateId = edit.stateAfter;
		undoStack.push(edit);
		return true;
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
			if (remaining <= lines[lineIndex].length) return sanitize(new BufferPosition(lineIndex, remaining));
			remaining -= lines[lineIndex].length + 1;
		}
		return endPosition();
	}

	function replace(selection:BufferSelection, from:BufferPosition, to:BufferPosition, value:String):Bool {
		var start = sanitize(from), end = sanitize(to);
		if (end.before(start)) {
			var swap = start;
			start = end;
			end = swap;
		}
		var removed = textRange(start, end), beforeCursor = selection.cursor, beforeAnchor = selection.anchor, beforeState = stateId;
		if (removed == value) return false;
		var afterState = nextStateId++;
		replaceRaw(start, end, value, beforeState, afterState);
		selection.collapse(this, advance(start, value));
		stateId = afterState;
		undoStack.push(new BufferEdit(start, removed, value, beforeCursor, beforeAnchor, selection.cursor, selection.anchor, beforeState, stateId));
		redoStack.resize(0);
		return true;
	}

	function replaceRaw(from:BufferPosition, to:BufferPosition, value:String, stateBefore:Int, stateAfter:Int):Void {
		var removed = textRange(from, to);
		var replacement = splitLines(value), prefix = lines[from.line].substring(0, from.column), suffix = lines[to.line].substring(to.column);
		replacement[0] = prefix + replacement[0];
		replacement[replacement.length - 1] += suffix;
		lines.splice(from.line, to.line - from.line + 1);
		for (index in 0...replacement.length) lines.insert(from.line + index, replacement[index]);
		var change = new BufferChange(from, removed, value, to.line - from.line, replacement.length - 1, stateBefore, stateAfter);
		var listeners = [for (listener in changeListeners) listener];
		for (listener in listeners) listener(change);
	}

	function advance(start:BufferPosition, value:String):BufferPosition {
		var inserted = splitLines(value);
		return inserted.length == 1 ? new BufferPosition(start.line, start.column + inserted[0].length) :
			new BufferPosition(start.line + inserted.length - 1, inserted[inserted.length - 1].length);
	}

	function sanitize(position:BufferPosition):BufferPosition {
		var line = position.line < 0 ? 0 : position.line >= lines.length ? lines.length - 1 : position.line,
			column = position.column < 0 ? 0 : position.column > lines[line].length ? lines[line].length : position.column;
		if (column > 0 && column < lines[line].length && isLowSurrogate(lines[line].charCodeAt(column))
			&& isHighSurrogate(lines[line].charCodeAt(column - 1))) column--;
		return new BufferPosition(line, column);
	}

	public function endPosition():BufferPosition
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

typedef BufferChangeListener = BufferChange -> Void;
