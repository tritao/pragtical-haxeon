package app;

import core.Application;
import platform.Native;
import platform.Platform;
import plugin.DynamicPlugin;
import plugin.PluginManifest;
import renderer.Renderer;
import sys.io.File;

class DynamicPluginTestMain {
	static function require(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function main():Int {
		var arguments = Sys.args();
		require(arguments.length == 2, "expected manifest and source paths");
		Platform.startHeadless();
		var window = Native.window_create("dynamic-plugin-test", 320, 200),
			renderer = new Renderer(window, "ignored-headlessly.ttf", 15),
			application = new Application(renderer, 320, 200),
			plugin = new DynamicPlugin(new PluginManifest(arguments[0]));
		require(application.plugins.load(plugin), "dynamic plugin did not load");
		require(application.commands.perform("example:increment", application.context), "dynamic command did not dispatch");
		require(plugin.callInt("current") == 1, "dynamic command did not update plugin state");

		var source = File.getContent(arguments[1]);
		File.saveContent(arguments[1], StringTools.replace(source, "PluginState.value + 1", "PluginState.value + 2"));
		require(plugin.refresh(), "compatible source edit did not publish");
		require(application.commands.perform("example:increment", application.context), "patched command did not dispatch");
		require(plugin.callInt("current") == 3, "compatible patch did not preserve state or replace behavior");

		application.shutdown();
		renderer.destroy();
		Platform.require(Native.window_destroy(window), "destroy dynamic plugin test window");
		Native.shutdown();
		Sys.println("PASS: manifest plugin loading and compatible hot reload");
		return 0;
	}
}
