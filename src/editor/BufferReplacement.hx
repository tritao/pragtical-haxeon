package editor;

class BufferReplacement {
	public final from:BufferPosition;
	public final to:BufferPosition;
	public final text:String;

	public function new(from:BufferPosition, to:BufferPosition, text:String) {
		this.from = from;
		this.to = to;
		this.text = text;
	}
}
