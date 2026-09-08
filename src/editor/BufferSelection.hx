package editor;

/** Mutable caret state owned by one editor view, never by a document buffer. */
class BufferSelection {
	public var cursor(default, null):BufferPosition;
	public var anchor(default, null):BufferPosition;
	var preferredColumn:Int = -1;

	public function new(?cursor:BufferPosition, ?anchor:BufferPosition) {
		this.cursor = cursor == null ? new BufferPosition(0, 0) : cursor;
		this.anchor = anchor == null ? this.cursor : anchor;
	}

	public function hasSelection():Bool
		return !cursor.equals(anchor);

	public function start():BufferPosition
		return cursor.before(anchor) ? cursor : anchor;

	public function end():BufferPosition
		return cursor.before(anchor) ? anchor : cursor;

	public function setCursor(buffer:TextBuffer, position:BufferPosition, extend:Bool = false):Void {
		buffer.breakHistoryGroup();
		cursor = buffer.positionAt(position.line, position.column);
		if (!extend) anchor = cursor;
		preferredColumn = -1;
	}

	public function restore(buffer:TextBuffer, cursor:BufferPosition, anchor:BufferPosition, breakHistoryGroup:Bool = true):Void {
		if (breakHistoryGroup) buffer.breakHistoryGroup();
		this.cursor = buffer.positionAt(cursor.line, cursor.column);
		this.anchor = buffer.positionAt(anchor.line, anchor.column);
		preferredColumn = -1;
	}

	public function move(buffer:TextBuffer, delta:Int, extend:Bool = false):Void
		setCursor(buffer, buffer.positionOffset(cursor, delta), extend);

	public function moveHome(buffer:TextBuffer, extend:Bool = false):Void
		setCursor(buffer, new BufferPosition(cursor.line, 0), extend);

	public function moveEnd(buffer:TextBuffer, extend:Bool = false):Void
		setCursor(buffer, new BufferPosition(cursor.line, buffer.line(cursor.line).length), extend);

	public function moveVertical(buffer:TextBuffer, delta:Int, extend:Bool = false):Void {
		if (preferredColumn < 0) preferredColumn = cursor.column;
		var targetLine = cursor.line + delta;
		if (targetLine < 0) targetLine = 0;
		else if (targetLine >= buffer.lineCount()) targetLine = buffer.lineCount() - 1;
		var column = preferredColumn > buffer.line(targetLine).length ? buffer.line(targetLine).length : preferredColumn;
		cursor = buffer.positionAt(targetLine, column);
		if (!extend) anchor = cursor;
	}

	public function selectAll(buffer:TextBuffer):Void {
		anchor = new BufferPosition(0, 0);
		cursor = buffer.endPosition();
		preferredColumn = -1;
	}

	public function selectedText(buffer:TextBuffer):String
		return hasSelection() ? buffer.textRange(start(), end()) : "";

	public function collapse(buffer:TextBuffer, position:BufferPosition, breakHistoryGroup:Bool = true):Void
		restore(buffer, position, position, breakHistoryGroup);

	public function transform(buffer:TextBuffer, change:BufferChange):Void {
		var transformedCursor = change.transform(cursor), transformedAnchor = change.transform(anchor);
		cursor = buffer.positionAt(transformedCursor.line, transformedCursor.column);
		anchor = buffer.positionAt(transformedAnchor.line, transformedAnchor.column);
		preferredColumn = -1;
	}
}
