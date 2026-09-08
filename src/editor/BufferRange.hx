package editor;

class BufferRange {
	public final cursor:BufferPosition;
	public final anchor:BufferPosition;

	public function new(cursor:BufferPosition, anchor:BufferPosition) {
		this.cursor = cursor;
		this.anchor = anchor;
	}

	public function start():BufferPosition return cursor.before(anchor) ? cursor : anchor;
	public function end():BufferPosition return cursor.before(anchor) ? anchor : cursor;
	public function isReversed():Bool return cursor.before(anchor);
	public function isCollapsed():Bool return cursor.equals(anchor);
}
