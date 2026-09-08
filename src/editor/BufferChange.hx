package editor;

/**
 * A completed text mutation. Positions and lengths use Haxe String UTF-16 code
 * units; line breaks occupy one logical offset regardless of their on-disk form.
 */
class BufferChange {
	public final start:BufferPosition;
	public final removed:String;
	public final inserted:String;
	public final removedLines:Int;
	public final insertedLines:Int;
	public final stateBefore:Int;
	public final stateAfter:Int;

	public function new(start:BufferPosition, removed:String, inserted:String, removedLines:Int, insertedLines:Int, stateBefore:Int,
			stateAfter:Int) {
		this.start = start;
		this.removed = removed;
		this.inserted = inserted;
		this.removedLines = removedLines;
		this.insertedLines = insertedLines;
		this.stateBefore = stateBefore;
		this.stateAfter = stateAfter;
	}
}
