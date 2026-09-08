package recovery;

class RecoverySnapshot {
	public final path:String;
	public final text:String;

	public function new(path:String, text:String) {
		this.path = path;
		this.text = text;
	}
}
