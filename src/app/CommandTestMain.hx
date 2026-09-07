package app;

import core.Application;
import command.CommandContext;
import platform.Native;
import platform.Platform;
import renderer.Renderer;

class CommandTestMain {
	static function require(condition:Bool, message:String):Void {
		if (!condition) throw message;
	}

	static function main():Int {
		Platform.startHeadless();
		var window = Native.window_create("command-test", 320, 200), renderer = new Renderer(window, "ignored-headlessly.ttf", 15),
			application = new Application(renderer, 320, 200), registry = application.commands, keymap = application.keymap,
			context = application.context, performed = 0;
		registry.add("test:disabled", function(context:CommandContext) { performed = 1; }, (context:CommandContext) -> false);
		registry.add("test:fallback", function(context:CommandContext) { performed = 2; });
		keymap.addDirect(100, 1, ["test:disabled", "test:fallback"]);
		require(keymap.onKeyPressed(100, 1, context) && performed == 2, "predicate fallback dispatch failed");
		registry.add("test:override", function(context:CommandContext) { performed = 3; });
		keymap.add(100, 1, ["test:override"]);
		performed = 0;
		require(keymap.onKeyPressed(100, 1, context) && performed == 3, "new binding did not take precedence");
		var ordered = keymap.commandsFor(100, 1);
		require(ordered.length == 3 && ordered[0] == "test:override", "binding precedence was not retained");
		registry.add("test:override", function(context:CommandContext) { performed = 4; });
		performed = 0;
		require(keymap.onKeyPressed(100, 1, context) && performed == 4, "duplicate command registration was not replaced");
		keymap.unbind(100, 1, "test:override");
		performed = 0;
		require(keymap.onKeyPressed(100, 1, context) && performed == 2, "command unbinding failed");
		keymap.addDirect(100, 1, ["test:disabled"]);
		require(!keymap.onKeyPressed(100, 1, context), "invalid command consumed key binding");
		renderer.destroy();
		Platform.require(Native.window_destroy(window), "destroy command test window");
		Native.shutdown();
		Sys.println("PASS: command predicates, replacement, binding precedence, and conflicts");
		return 0;
	}
}
