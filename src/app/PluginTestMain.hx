package app;

import command.CommandContext;
import core.Application;
import platform.Native;
import platform.Platform;
import plugin.Plugin;
import plugin.PluginContext;
import renderer.Renderer;
import syntax.BuiltinSyntax;
import jobs.JobTask;

class SampleJob implements JobTask {
	public var cancelled(default, null):Bool = false;
	public function new() {}
	public function step():Bool return false;
	public function cancel():Void cancelled = true;
}

class SamplePlugin implements Plugin {
	public var activations(default, null):Int = 0;
	public var deactivations(default, null):Int = 0;
	public var performed(default, null):Int = 0;
	public var events(default, null):Int = 0;
	public final job:SampleJob = new SampleJob();

	public function new() {}

	public function id():String
		return "sample";

	public function activate(context:PluginContext):Void {
		activations++;
		context.addSyntax(BuiltinSyntax.definition("Sample", [".sample"], ["sample"], [], []));
		context.addCommand("sample:run", function(editor:CommandContext) {
			this.performed++;
			context.api.replaceSelections("plugin");
		});
		context.bind(77, 3, ["sample:run"]);
		context.api.addPanel("status", "Sample", "ready");
		context.api.onDocumentChanged(function(event) {
			this.events++;
			context.api.setPanelText("status", event.document.buffer.text);
		});
		context.api.schedule(job);
	}

	public function deactivate(context:PluginContext):Void
		deactivations++;

	public function refresh():Bool
		return false;

	public function update(now:Float):Bool
		return false;

	public function diagnostic():Null<String>
		return null;

	public function dispose():Void {}
}

class BrokenPlugin implements Plugin {
	public function new() {}

	public function id():String
		return "broken";

	public function activate(context:PluginContext):Void {
		context.addCommand("broken:leak", function(editor:CommandContext) {});
		context.bind(1, 0, ["root:close"]);
	}

	public function deactivate(context:PluginContext):Void {}

	public function refresh():Bool
		return false;

	public function update(now:Float):Bool
		return false;

	public function diagnostic():Null<String>
		return null;

	public function dispose():Void {}
}

class PluginTestMain {
	static function require(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function main():Int {
		Platform.startHeadless();
		var window = Native.window_create("plugin-test", 320, 200),
			renderer = new Renderer(window, "ignored-headlessly.ttf", 15),
			application = new Application(renderer, 320, 200),
			plugin = new SamplePlugin();
		application.newDocument();
		require(application.plugins.load(plugin), "plugin did not activate");
		require(plugin.activations == 1 && application.plugins.isLoaded("sample"), "plugin activation state was not recorded");
		require(application.syntaxes.find("file.sample").name == "Sample", "plugin syntax did not register");
		require(!application.plugins.load(new SamplePlugin()), "duplicate plugin id was accepted");
		require(application.keyPressed(77, 3) && plugin.performed == 1 && plugin.events == 1
			&& application.context.requireDocument().buffer.text == "plugin", "plugin command did not perform an owned document transaction");
		var panel = application.root.pluginPanels.find("sample", "status");
		require(panel != null && panel.text == "plugin", "plugin panel or document event contribution was not live");
		application.openCommandView();
		application.textInput("samplerun");
		require(application.root.commandView.results.length == 1, "plugin command was absent from command view");
		application.keyPressed(Platform.KEY_ENTER, 0);
		require(plugin.performed == 2, "plugin command palette entry did not dispatch");
		require(application.plugins.unload("sample"), "plugin did not unload");
		require(plugin.deactivations == 1 && !application.commands.contains("sample:run") && !application.keyPressed(77, 3),
			"plugin registrations survived unload");
		var eventsAfterUnload = plugin.events;
		application.textInput("after");
		require(application.root.pluginPanels.find("sample", "status") == null && plugin.events == eventsAfterUnload && plugin.job.cancelled,
			"plugin panel, event subscription, or scheduled job survived unload");
		require(application.syntaxes.find("file.sample").name == "Plain Text", "plugin syntax survived unload");
		require(application.plugins.reload(plugin) && plugin.activations == 2, "plugin did not reload");
		var failed = false;
		try {
			application.plugins.load(new BrokenPlugin());
		} catch (error:Dynamic) {
			failed = true;
		}
		require(failed
			&& !application.plugins.isLoaded("broken")
			&& !application.commands.contains("broken:leak"), "failed activation leaked plugin state");
		application.shutdown();
		require(plugin.deactivations == 2 && application.plugins.count() == 0, "application shutdown did not deactivate plugins");
		renderer.destroy();
		Platform.require(Native.window_destroy(window), "destroy plugin test window");
		Native.shutdown();
		Sys.println("PASS: plugin activation, palette dispatch, rollback, reload, and cleanup");
		return 0;
	}
}
