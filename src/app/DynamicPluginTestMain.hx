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
		var separator = arguments[0].lastIndexOf("/"), pluginDirectory = arguments[0].substring(0, separator), incompatiblePath = pluginDirectory + "/incompatible.conf";
		File.saveContent(incompatiblePath, "manifestVersion=1\napiVersion=99\nid=incompatible\nversion=1.0.0\nsource=Main.hx\n");
		var errorsBeforeIncompatible = application.errors.entries.length;
		require(!application.loadPluginManifest(incompatiblePath) && application.errors.entries.length == errorsBeforeIncompatible + 1,
			"incompatible plugin API was not rejected with a visible diagnostic");
		application.newDocument();
		require(application.plugins.load(plugin), "dynamic plugin did not load");
		require(application.syntaxes.find("file.example").name == "Example", "manifest syntax did not register");
		require(plugin.callInt("hostProbe") == 42, "dynamic plugin direct host API probe failed");
		require(application.root.pluginPanels.find("example", "status") != null, "dynamic plugin did not invoke the host panel API during activation");
		application.context.requireView().undo();
		var eventsBeforeCommand = plugin.callInt("eventCount");
		require(application.commands.perform("example:increment", application.context), "dynamic command did not dispatch");
		require(plugin.callInt("current") == 1, "dynamic command did not update plugin state");
		require(application.context.requireDocument().buffer.text == "dynamic", "dynamic command did not invoke the host document transaction API");
		require(plugin.callInt("eventCount") == eventsBeforeCommand + 1, "dynamic document event did not invoke the plugin callback exactly once");
		var panel = application.root.pluginPanels.find("example", "status");
		require(panel != null && panel.text == "dynamic", "dynamic plugin panel did not observe the document event");

		var source = File.getContent(arguments[1]);
		File.saveContent(arguments[1], StringTools.replace(source, "PluginState.value + 1", "PluginState.value + 2"));
		require(plugin.refresh(), 'compatible source edit did not publish: ${plugin.lastError}');
		require(application.commands.perform("example:increment", application.context), "patched command did not dispatch");
		require(plugin.callInt("current") == 3, "compatible patch did not preserve state or replace behavior");
		var eventsAfterPatchedCommand = plugin.callInt("eventCount");
		require(application.context.requireDocument().buffer.text == "dynamicdynamic" && eventsAfterPatchedCommand == eventsBeforeCommand + 2,
			"patched dynamic plugin lost host API access or duplicated its event subscription");
		require(application.plugins.unload("example"), "dynamic plugin did not unload");
		var textAfterUnload = application.context.requireDocument().buffer.text;
		application.textInput("after");
		require(application.root.pluginPanels.find("example", "status") == null
			&& application.context.requireDocument().buffer.text != textAfterUnload, "dynamic plugin panel survived unload");

		application.shutdown();
		renderer.destroy();
		Platform.require(Native.window_destroy(window), "destroy dynamic plugin test window");
		Native.shutdown();
		Sys.println("PASS: manifest plugin loading and compatible hot reload");
		return 0;
	}
}
