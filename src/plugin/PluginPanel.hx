package plugin;

class PluginPanel {
	public final owner:String;
	public final id:String;
	public final title:String;
	public var text:String;

	public function new(owner:String, id:String, title:String, text:String) {
		this.owner = owner;
		this.id = id;
		this.title = title;
		this.text = text;
	}
}
