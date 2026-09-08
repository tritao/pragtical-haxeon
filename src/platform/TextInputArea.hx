package platform;

/** Logical-point candidate-window placement for the active text surface. */
class TextInputArea {
	public final x:Int;
	public final y:Int;
	public final width:Int;
	public final height:Int;
	public final cursor:Int;

	public function new(x:Int, y:Int, width:Int, height:Int, cursor:Int = 0) {
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		this.cursor = cursor;
	}
}
