package command;

class KeyBinding {
	public final key:Int;
	public final modifiers:Int;
	public final commands:Array<String>;

	public function new(key:Int, modifiers:Int, commands:Array<String>) {
		this.key = key;
		this.modifiers = modifiers;
		this.commands = commands;
	}
}
