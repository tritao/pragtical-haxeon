package editor;

class BracketPair {
	public final first:BufferPosition;
	public final second:BufferPosition;

	public function new(first:BufferPosition, second:BufferPosition) {
		this.first = first;
		this.second = second;
	}
}
