package recovery;

class RecoverySnapshot {
	public final id:String;
	public final title:String;
	public final path:Null<String>;
	public final text:String;

	public function new(id:String, title:String, path:Null<String>, text:String) {
		this.id = id;
		this.title = title;
		this.path = path;
		this.text = text;
	}
}
