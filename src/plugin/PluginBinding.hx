package plugin;

class PluginBinding {
	public final key:Int;
	public final modifiers:Int;
	public final command:String;

	public function new(key:Int, modifiers:Int, command:String) {
		this.key = key;
		this.modifiers = modifiers;
		this.command = command;
	}
}
