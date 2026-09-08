package editor;

class BufferSubscription {
	var buffer:Null<TextBuffer>;
	final id:Int;

	public function new(buffer:TextBuffer, id:Int) {
		this.buffer = buffer;
		this.id = id;
	}

	public function release():Void {
		var owner = buffer;
		if (owner == null) return;
		buffer = null;
		owner.releaseSubscription(id);
	}
}
