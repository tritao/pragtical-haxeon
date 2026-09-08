package editor;

class TextBuffer {
	final lines:Array<String>;
	final changeListeners:Map<Int, BufferChangeListener> = [];
	var nextListenerId:Int = 1;
	public var stateId(default, null):Int = 0;
	var nextStateId:Int = 1;
	final undoStack:Array<BufferTransaction> = [];
	final redoStack:Array<BufferTransaction> = [];
	var historyGroupOpen:Bool = false;
	final transactionEdits:Array<BufferEdit> = [];
	var inTransaction:Bool = false;
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

	public function insert(selection:BufferSelection, value:String, typing:Bool = false):Bool {
		if (value.length == 0 && !selection.hasSelection()) return false;
		return replace(selection, selection.start(), selection.end(), value, typing ? "typing" : "");
	}

	public function replaceRange(selection:BufferSelection, from:BufferPosition, to:BufferPosition, value:String):Bool
		return replace(selection, from, to, value);

	public function replaceAllText(value:String, ?selection:BufferSelection):Bool {
		var owner = selection == null ? new BufferSelection() : selection;
		return replace(owner, new BufferPosition(0, 0), endPosition(), value);
	}

	/** Applies non-overlapping replacements from the end of the document as one undo unit. */
	public function applyReplacements(selection:BufferSelection, replacements:Array<BufferReplacement>):Bool {
		if (inTransaction || replacements.length == 0) return false;
		var ordered:Array<BufferReplacement> = [];
		for (replacement in replacements) {
			var from = positionAt(replacement.from.line, replacement.from.column), to = positionAt(replacement.to.line, replacement.to.column);
			if (to.before(from)) {
				var swap = from;
				from = to;
				to = swap;
			}
			ordered.push(new BufferReplacement(from, to, replacement.text));
		}
		ordered.sort(function(left, right) {
			var leftStart = positionAt(left.from.line, left.from.column), rightStart = positionAt(right.from.line, right.from.column);
			if (leftStart.line != rightStart.line) return rightStart.line - leftStart.line;
			return rightStart.column - leftStart.column;
		});
		for (index in 0...ordered.length - 1) {
			var higherStart = positionAt(ordered[index].from.line, ordered[index].from.column),
				lowerEnd = positionAt(ordered[index + 1].to.line, ordered[index + 1].to.column);
			if (higherStart.before(lowerEnd)) return false;
		}
		breakHistoryGroup();
		transactionEdits.resize(0);
		inTransaction = true;
		for (replacement in ordered)
			replace(selection, replacement.from, replacement.to, replacement.text);
		inTransaction = false;
		var completed = transactionEdits.copy();
		transactionEdits.resize(0);
		if (completed.length == 0) return false;
		var transaction = new BufferTransaction(completed[0], "");
		for (index in 1...completed.length) transaction.edits.push(completed[index]);
		undoStack.push(transaction);
		redoStack.resize(0);
		return true;
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
		if (undoStack.length == 0) return false;
		var transaction = undoStack.pop();
		if (transaction == null) return false;
		var index = transaction.edits.length;
		while (index > 0) {
			index--;
			var edit = transaction.edits[index];
			replaceRaw(edit.start, advance(edit.start, edit.inserted), edit.removed, edit.stateAfter, edit.stateBefore);
		}
		selection.restore(this, transaction.cursorBefore, transaction.anchorBefore, false);
		stateId = transaction.stateBefore;
		redoStack.push(transaction);
		historyGroupOpen = false;
		return true;
	}

	public function redo(selection:BufferSelection):Bool {
		if (redoStack.length == 0) return false;
		var transaction = redoStack.pop();
		if (transaction == null) return false;
		for (edit in transaction.edits)
			replaceRaw(edit.start, advance(edit.start, edit.removed), edit.inserted, edit.stateBefore, edit.stateAfter);
		selection.restore(this, transaction.cursorAfter, transaction.anchorAfter, false);
		stateId = transaction.stateAfter;
		undoStack.push(transaction);
		historyGroupOpen = false;
		return true;
	}

	public function breakHistoryGroup():Void
		historyGroupOpen = false;

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

	public function characterCodeAt(position:BufferPosition):Int {
		var value = sanitize(position);
		if (value.column < lines[value.line].length) return lines[value.line].charCodeAt(value.column);
		return value.line + 1 < lines.length ? 10 : -1;
	}

	public function wordStartAt(position:BufferPosition):BufferPosition {
		var result = sanitize(position);
		if (!isWordCode(characterCodeAt(result))) return result;
		while (result.line != 0 || result.column != 0) {
			var previous = positionOffset(result, -1);
			if (!isWordCode(characterCodeAt(previous))) break;
			result = previous;
		}
		return result;
	}

	public function wordEndAt(position:BufferPosition):BufferPosition {
		var result = sanitize(position), end = endPosition();
		if (!isWordCode(characterCodeAt(result))) return positionOffset(result, 1);
		while (!result.equals(end) && isWordCode(characterCodeAt(result))) result = positionOffset(result, 1);
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

	function replace(selection:BufferSelection, from:BufferPosition, to:BufferPosition, value:String, group:String = ""):Bool {
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
		selection.collapse(this, advance(start, value), false);
		stateId = afterState;
		var edit = new BufferEdit(start, removed, value, beforeCursor, beforeAnchor, selection.cursor, selection.anchor, beforeState, stateId);
		if (inTransaction) transactionEdits.push(edit);
		else {
			var previous = undoStack.length == 0 ? null : undoStack[undoStack.length - 1];
			if (historyGroupOpen && previous != null && previous.canAppend(edit, group)) previous.edits.push(edit);
			else undoStack.push(new BufferTransaction(edit, group));
		}
		historyGroupOpen = group.length > 0;
		if (!inTransaction) redoStack.resize(0);
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

	static function isWordCode(code:Int):Bool
		return code >= 48 && code <= 57 || code >= 65 && code <= 90 || code >= 97 && code <= 122 || code == 95 || code >= 128;
}

typedef BufferChangeListener = BufferChange -> Void;
