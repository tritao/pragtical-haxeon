package editor;

class SelectionSnapshot {
	public final ranges:Array<BufferRange>;
	public final primary:Int;

	public function new(ranges:Array<BufferRange>, primary:Int) {
		this.ranges = ranges;
		this.primary = primary;
	}
}
