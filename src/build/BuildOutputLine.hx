package build;

class BuildOutputLine {
	public final text:String;
	public final diagnostic:Null<BuildDiagnostic>;

	public function new(text:String, ?diagnostic:BuildDiagnostic) {
		this.text = text;
		this.diagnostic = diagnostic;
	}
}
