package editor;

class FoldRegion {
	public final startLine:Int;
	public final endLine:Int;

	public function new(startLine:Int, endLine:Int) {
		if (startLine < 0 || endLine <= startLine) throw "fold region must hide at least one following line";
		this.startLine = startLine;
		this.endLine = endLine;
	}

	public function contains(line:Int):Bool
		return line > startLine && line <= endLine;
}
