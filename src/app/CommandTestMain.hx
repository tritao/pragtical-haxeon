package app;

import command.CommandRegistry;
import command.Keymap;

class CommandTestMain {
	static function require(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function main():Int {
		var registry = new CommandRegistry(), keymap = new Keymap(registry), performed = 0;
		registry.add("test:disabled", function() { performed = 1; return; }, function() { return false; });
		registry.add("test:fallback", function() { performed = 2; return; });
		keymap.addDirect(10, 1, ["test:disabled", "test:fallback"]);
		require(keymap.onKeyPressed(10, 1) && performed == 2, "predicate fallback dispatch failed");

		registry.add("test:override", function() { performed = 3; return; });
		keymap.add(10, 1, ["test:override"]);
		performed = 0;
		require(keymap.onKeyPressed(10, 1) && performed == 3, "new binding did not take precedence");
		var ordered = keymap.commandsFor(10, 1);
		require(ordered.length == 3 && ordered[0] == "test:override", "binding precedence was not retained");

		registry.add("test:override", function() { performed = 4; return; });
		performed = 0;
		require(keymap.onKeyPressed(10, 1) && performed == 4, "duplicate command registration was not replaced");
		keymap.unbind(10, 1, "test:override");
		performed = 0;
		require(keymap.onKeyPressed(10, 1) && performed == 2, "command unbinding failed");

		keymap.addDirect(10, 1, ["test:disabled"]);
		require(!keymap.onKeyPressed(10, 1), "invalid command consumed key binding");
		Sys.println("PASS: command predicates, replacement, binding precedence, and conflicts");
		return 0;
	}
}
