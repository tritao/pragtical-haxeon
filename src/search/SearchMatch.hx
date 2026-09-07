package search;

class SearchMatch {
	public final path:String;
	public final line:Int;
	public final column:Int;
	public final length:Int;
	public final preview:String;

	public function new(path:String, line:Int, column:Int, length:Int, preview:String) {
		this.path = path;
		this.line = line;
		this.column = column;
		this.length = length;
		this.preview = preview;
	}
}
