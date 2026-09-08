package build;

class BuildDiagnostic {
	public final path:String;
	public final line:Int;
	public final column:Int;

	public function new(path:String, line:Int, column:Int) {
		this.path = path;
		this.line = line;
		this.column = column;
	}
}
