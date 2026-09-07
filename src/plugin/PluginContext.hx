package plugin;

import command.CommandContext;
import command.CommandRegistry;
import command.Keymap;

class PluginContext {
	public final id:String;
	public final editor:CommandContext;
	final commands:CommandRegistry;
	final keymap:Keymap;
	final commandNames:Array<String> = [];
	final bindings:Array<PluginBinding> = [];
	var active:Bool = true;

	public function new(id:String, commands:CommandRegistry, keymap:Keymap, editor:CommandContext) {
		this.id = id;
		this.editor = editor;
		this.commands = commands;
		this.keymap = keymap;
	}

	public function addCommand(name:String, perform:CommandContext->Void, ?predicate:CommandContext->Bool):Void {
		requireActive();
		if (!StringTools.startsWith(name, id + ":"))
			throw 'plugin "$id" command must use the "$id:" namespace';
		if (commands.contains(name))
			throw 'command "$name" is already registered';
		commands.add(name, perform, predicate);
		commandNames.push(name);
	}

	public function bind(key:Int, modifiers:Int, names:Array<String>):Void {
		requireActive();
		for (name in names) {
			if (commandNames.indexOf(name) < 0)
				throw 'plugin "$id" cannot bind command it does not own: "$name"';
			keymap.add(key, modifiers, [name]);
			bindings.push(new PluginBinding(key, modifiers, name));
		}
	}

	public function dispose():Void {
		if (!active) return;
		var index = bindings.length;
		while (index > 0) {
			index--;
			var binding = bindings[index];
			keymap.unbind(binding.key, binding.modifiers, binding.command);
		}
		for (name in commandNames) {
			keymap.removeCommand(name);
			commands.remove(name);
		}
		active = false;
	}

	function requireActive():Void {
		if (!active) throw 'plugin "$id" context is no longer active';
	}
}
