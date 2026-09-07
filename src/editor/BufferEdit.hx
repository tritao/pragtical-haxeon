package editor;

class BufferEdit {
	public final start:BufferPosition;
	public final removed:String;
	public final inserted:String;
	public final cursorBefore:BufferPosition;
	public final anchorBefore:BufferPosition;
	public final cursorAfter:BufferPosition;
	public final anchorAfter:BufferPosition;
	public final stateBefore:Int;
	public final stateAfter:Int;

	public function new(start:BufferPosition, removed:String, inserted:String, cursorBefore:BufferPosition, anchorBefore:BufferPosition,
			cursorAfter:BufferPosition, anchorAfter:BufferPosition, stateBefore:Int, stateAfter:Int) {
		this.start = start;
		this.removed = removed;
		this.inserted = inserted;
		this.cursorBefore = cursorBefore;
		this.anchorBefore = anchorBefore;
		this.cursorAfter = cursorAfter;
		this.anchorAfter = anchorAfter;
		this.stateBefore = stateBefore;
		this.stateAfter = stateAfter;
	}
}
