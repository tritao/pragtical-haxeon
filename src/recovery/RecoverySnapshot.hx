package recovery;

class RecoverySnapshot {
	public final id:Int;
	public final title:String;
	public final path:Null<String>;
	public final text:String;

	public function new(id:Int, title:String, path:Null<String>, text:String) {
		this.id = id;
		this.title = title;
		this.path = path;
		this.text = text;
	}
}
