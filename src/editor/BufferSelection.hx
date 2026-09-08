package editor;

/** Mutable caret state owned by one editor view, never by a document buffer. */
class BufferSelection {
	public var cursor(default, null):BufferPosition;
	public var anchor(default, null):BufferPosition;
	var preferredColumn:Int = -1;
	final additional:Array<BufferRange> = [];

	public function new(?cursor:BufferPosition, ?anchor:BufferPosition) {
		this.cursor = cursor == null ? new BufferPosition(0, 0) : cursor;
		this.anchor = anchor == null ? this.cursor : anchor;
	}

	public function hasSelection():Bool
		return !cursor.equals(anchor);

	public function rangeCount():Int return additional.length + 1;

	public function allRanges():Array<BufferRange> {
		var result = [new BufferRange(cursor, anchor)];
		for (range in additional) result.push(range);
		return result;
	}

	/** Returns normalized ranges in document order for clipboard distribution. */
	public function documentRanges():Array<BufferRange> {
		var result = allRanges();
		result.sort(function(left, right) {
			var leftStart = left.start(), rightStart = right.start();
			if (leftStart.line != rightStart.line) return leftStart.line - rightStart.line;
			return leftStart.column - rightStart.column;
		});
		return result;
	}

	public function snapshot():SelectionSnapshot
		return new SelectionSnapshot(allRanges(), 0);

	public function start():BufferPosition
		return cursor.before(anchor) ? cursor : anchor;

	public function end():BufferPosition
		return cursor.before(anchor) ? anchor : cursor;

	public function setCursor(buffer:TextBuffer, position:BufferPosition, extend:Bool = false):Void {
		buffer.breakHistoryGroup();
		cursor = buffer.positionAt(position.line, position.column);
		if (!extend) anchor = cursor;
		additional.resize(0);
		preferredColumn = -1;
	}

	public function restore(buffer:TextBuffer, cursor:BufferPosition, anchor:BufferPosition, breakHistoryGroup:Bool = true):Void {
		if (breakHistoryGroup) buffer.breakHistoryGroup();
		this.cursor = buffer.positionAt(cursor.line, cursor.column);
		this.anchor = buffer.positionAt(anchor.line, anchor.column);
		additional.resize(0);
		preferredColumn = -1;
	}

	public function move(buffer:TextBuffer, delta:Int, extend:Bool = false):Void {
		if (moveAll(buffer, 0, delta, extend)) return;
		if (!extend && hasSelection()) {
			setCursor(buffer, delta < 0 ? start() : end());
			return;
		}
		setCursor(buffer, buffer.positionOffset(cursor, delta), extend);
	}

	public function moveWord(buffer:TextBuffer, direction:Int, extend:Bool = false):Void {
		if (moveAll(buffer, 1, direction, extend)) return;
		if (!extend && hasSelection()) {
			setCursor(buffer, direction < 0 ? start() : end());
			return;
		}
		var position = cursor;
		if (direction < 0) {
			while (!position.equals(new BufferPosition(0, 0))) {
				var previous = buffer.positionOffset(position, -1);
				if (isWord(buffer.characterCodeAt(previous))) break;
				position = previous;
			}
			while (!position.equals(new BufferPosition(0, 0))) {
				var previous = buffer.positionOffset(position, -1);
				if (!isWord(buffer.characterCodeAt(previous))) break;
				position = previous;
			}
		} else {
			var end = buffer.endPosition();
			while (!position.equals(end) && isWord(buffer.characterCodeAt(position))) position = buffer.positionOffset(position, 1);
			while (!position.equals(end) && !isWord(buffer.characterCodeAt(position))) position = buffer.positionOffset(position, 1);
		}
		setCursor(buffer, position, extend);
	}

	public function moveHome(buffer:TextBuffer, extend:Bool = false):Void
		if (!moveAll(buffer, 2, 0, extend)) setCursor(buffer, new BufferPosition(cursor.line, 0), extend);

	public function moveEnd(buffer:TextBuffer, extend:Bool = false):Void
		if (!moveAll(buffer, 3, 0, extend)) setCursor(buffer, new BufferPosition(cursor.line, buffer.line(cursor.line).length), extend);

	public function moveDocumentStart(buffer:TextBuffer, extend:Bool = false):Void
		if (!moveAll(buffer, 4, 0, extend)) setCursor(buffer, new BufferPosition(0, 0), extend);

	public function moveDocumentEnd(buffer:TextBuffer, extend:Bool = false):Void
		if (!moveAll(buffer, 5, 0, extend)) setCursor(buffer, buffer.endPosition(), extend);

	public function moveVertical(buffer:TextBuffer, delta:Int, extend:Bool = false):Void {
		if (moveAll(buffer, 6, delta, extend)) return;
		if (preferredColumn < 0) preferredColumn = cursor.column;
		var targetLine = cursor.line + delta;
		if (targetLine < 0) targetLine = 0;
		else if (targetLine >= buffer.lineCount()) targetLine = buffer.lineCount() - 1;
		var column = preferredColumn > buffer.line(targetLine).length ? buffer.line(targetLine).length : preferredColumn;
		cursor = buffer.positionAt(targetLine, column);
		if (!extend) anchor = cursor;
	}

	public function selectAll(buffer:TextBuffer):Void {
		buffer.breakHistoryGroup();
		anchor = new BufferPosition(0, 0);
		cursor = buffer.endPosition();
		additional.resize(0);
		preferredColumn = -1;
	}

	public function selectedText(buffer:TextBuffer):String
		return hasSelection() ? buffer.textRange(start(), end()) : "";

	public function collapse(buffer:TextBuffer, position:BufferPosition, breakHistoryGroup:Bool = true):Void
		restore(buffer, position, position, breakHistoryGroup);

	public function transform(buffer:TextBuffer, change:BufferChange):Void {
		var transformed:Array<BufferRange> = [];
		for (range in allRanges()) transformed.push(new BufferRange(change.transform(range.cursor), change.transform(range.anchor)));
		setRanges(buffer, transformed, 0, false);
		preferredColumn = -1;
	}

	public function restoreSnapshot(buffer:TextBuffer, snapshot:SelectionSnapshot, breakHistoryGroup:Bool = true):Void
		setRanges(buffer, snapshot.ranges, snapshot.primary, breakHistoryGroup);

	public function addRange(buffer:TextBuffer, cursor:BufferPosition, anchor:BufferPosition):Void {
		var ranges = allRanges();
		ranges.push(new BufferRange(cursor, anchor));
		setRanges(buffer, ranges, 0);
	}

	public function setRanges(buffer:TextBuffer, ranges:Array<BufferRange>, primary:Int = 0, breakHistoryGroup:Bool = true):Void {
		if (breakHistoryGroup) buffer.breakHistoryGroup();
		if (ranges.length == 0) ranges = [new BufferRange(new BufferPosition(0, 0), new BufferPosition(0, 0))];
		if (primary < 0 || primary >= ranges.length) primary = 0;
		var primaryRange = ranges[primary], ordered:Array<BufferRange> = [];
		for (range in ranges)
			ordered.push(new BufferRange(buffer.positionAt(range.cursor.line, range.cursor.column), buffer.positionAt(range.anchor.line, range.anchor.column)));
		ordered.sort(function(left, right) {
			var leftStart = left.start(), rightStart = right.start();
			if (leftStart.line != rightStart.line) return leftStart.line - rightStart.line;
			return leftStart.column - rightStart.column;
		});
		var merged:Array<BufferRange> = [], primaryMerged = 0;
		for (range in ordered) {
			var isPrimary = range.cursor.equals(buffer.positionAt(primaryRange.cursor.line, primaryRange.cursor.column))
				&& range.anchor.equals(buffer.positionAt(primaryRange.anchor.line, primaryRange.anchor.column));
			if (merged.length == 0 || merged[merged.length - 1].end().before(range.start())) {
				merged.push(range);
				if (isPrimary) primaryMerged = merged.length - 1;
			} else {
				var index = merged.length - 1, previous = merged[index], from = previous.start(), to = previous.end();
				if (to.before(range.end())) to = range.end();
				var reversed = isPrimary ? range.isReversed() : previous.isReversed();
				merged[index] = reversed ? new BufferRange(from, to) : new BufferRange(to, from);
				if (isPrimary) primaryMerged = index;
			}
		}
		var chosen = merged[primaryMerged];
		cursor = chosen.cursor;
		anchor = chosen.anchor;
		additional.resize(0);
		for (index in 0...merged.length) if (index != primaryMerged) additional.push(merged[index]);
		preferredColumn = -1;
	}

	static function isWord(code:Int):Bool
		return code >= 48 && code <= 57 || code >= 65 && code <= 90 || code >= 97 && code <= 122 || code == 95 || code >= 128;

	function moveAll(buffer:TextBuffer, operation:Int, amount:Int, extend:Bool):Bool {
		if (additional.length == 0) return false;
		var moved:Array<BufferRange> = [];
		for (range in allRanges()) {
			var temporary = new BufferSelection(range.cursor, range.anchor);
			if (operation == 0) temporary.move(buffer, amount, extend);
			else if (operation == 1) temporary.moveWord(buffer, amount, extend);
			else if (operation == 2) temporary.moveHome(buffer, extend);
			else if (operation == 3) temporary.moveEnd(buffer, extend);
			else if (operation == 4) temporary.moveDocumentStart(buffer, extend);
			else if (operation == 5) temporary.moveDocumentEnd(buffer, extend);
			else temporary.moveVertical(buffer, amount, extend);
			moved.push(new BufferRange(temporary.cursor, temporary.anchor));
		}
		setRanges(buffer, moved, 0);
		return true;
	}
}
