package plugin;

class DynamicCommand {
	public final name:String;
	public final functionName:String;
	public final key:Int;
	public final modifiers:Int;

	public function new(name:String, functionName:String, key:Int, modifiers:Int) {
		this.name = name;
		this.functionName = functionName;
		this.key = key;
		this.modifiers = modifiers;
	}
}
