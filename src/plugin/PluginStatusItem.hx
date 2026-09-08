package plugin;

class PluginStatusItem {
	public final owner:String;
	public final id:String;
	public var text:String;
	public final priority:Int;

	public function new(owner:String, id:String, text:String, priority:Int) {
		this.owner = owner;
		this.id = id;
		this.text = text;
		this.priority = priority;
	}
}
