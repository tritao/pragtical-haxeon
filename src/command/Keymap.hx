package command;

class Keymap {
	final registry:CommandRegistry;
	final bindings:Array<KeyBinding> = [];

	public function new(registry:CommandRegistry) {
		this.registry = registry;
	}

	public function addDirect(key:Int, modifiers:Int, commands:Array<String>):Void {
		var binding = find(key, modifiers);
		if (binding != null)
			bindings.remove(binding);
		bindings.push(new KeyBinding(key, modifiers, copy(commands)));
	}

	public function add(key:Int, modifiers:Int, commands:Array<String>, overwrite:Bool = false):Void {
		if (overwrite) {
			addDirect(key, modifiers, commands);
			return;
		}
		var binding = find(key, modifiers);
		if (binding == null) {
			addDirect(key, modifiers, commands);
			return;
		}
		for (index in 0...commands.length) {
			var command = commands[commands.length - index - 1];
			if (!contains(binding.commands, command))
				binding.commands.unshift(command);
		}
	}

	public function unbind(key:Int, modifiers:Int, command:String):Void {
		var binding = find(key, modifiers);
		if (binding != null)
			binding.commands.remove(command);
	}

	public function onKeyPressed(key:Int, modifiers:Int, context:CommandContext):Bool {
		var binding = find(key, modifiers);
		if (binding == null)
			return false;
		for (command in binding.commands)
			if (registry.perform(command, context))
				return true;
		return false;
	}

	public function commandsFor(key:Int, modifiers:Int):Array<String> {
		var binding = find(key, modifiers);
		return binding == null ? [] : copy(binding.commands);
	}

	function find(key:Int, modifiers:Int):Null<KeyBinding> {
		for (binding in bindings)
			if (binding.key == key && binding.modifiers == modifiers)
				return binding;
		return null;
	}

	static function contains(values:Array<String>, value:String):Bool {
		for (existing in values)
			if (existing == value)
				return true;
		return false;
	}

	static function copy(values:Array<String>):Array<String> {
		var result:Array<String> = [];
		for (value in values)
			result.push(value);
		return result;
	}

}
