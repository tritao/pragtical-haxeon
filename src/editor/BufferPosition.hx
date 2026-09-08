package editor;

/** A zero-based line and UTF-16 code-unit column at a Unicode scalar boundary. */
class BufferPosition {
	public final line:Int;
	public final column:Int;

	public function new(line:Int, column:Int) {
		this.line = line;
		this.column = column;
	}

	public function equals(other:BufferPosition):Bool
		return line == other.line && column == other.column;

	public function before(other:BufferPosition):Bool
		return line < other.line || line == other.line && column < other.column;
}
