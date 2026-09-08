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

	/** Maps a passive view position through this edit with left affinity at insertions. */
	public function transform(position:BufferPosition):BufferPosition {
		if (!start.before(position)) return position;
		var removedEnd = advance(start, removed), insertedEnd = advance(start, inserted);
		if (!removedEnd.before(position)) return insertedEnd;
		if (position.line == removedEnd.line)
			return new BufferPosition(insertedEnd.line, insertedEnd.column + position.column - removedEnd.column);
		return new BufferPosition(position.line + insertedEnd.line - removedEnd.line, position.column);
	}

	static function advance(start:BufferPosition, value:String):BufferPosition {
		var lines = value.split("\n");
		return lines.length == 1 ? new BufferPosition(start.line, start.column + value.length) :
			new BufferPosition(start.line + lines.length - 1, lines[lines.length - 1].length);
	}
}
