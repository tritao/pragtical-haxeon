package editor;

class VisualLine {
	public final documentLine:Int;
	public final startColumn:Int;
	public final endColumn:Int;
	public final foldedThroughLine:Int;

	public function new(documentLine:Int, startColumn:Int, endColumn:Int, foldedThroughLine:Int = -1) {
		this.documentLine = documentLine;
		this.startColumn = startColumn;
		this.endColumn = endColumn;
		this.foldedThroughLine = foldedThroughLine;
	}
}
