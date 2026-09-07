package editor;

class BufferSnapshot {
	public final text:String;
	public final cursor:Int;
	public final anchor:Int;

	public function new(text:String, cursor:Int, anchor:Int) {
		this.text = text;
		this.cursor = cursor;
		this.anchor = anchor;
	}
}
