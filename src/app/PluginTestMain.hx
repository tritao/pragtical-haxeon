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
import completion.CompletionItem;
import completion.CompletionProvider;
import completion.CompletionRequest;
import plugin.EditorApi;

class SampleCompletionProvider implements CompletionProvider {
	public function new() {}
	public function complete(request:CompletionRequest):Array<CompletionItem>
		return StringTools.startsWith("pluginCompletion", request.prefix) ? [new CompletionItem("pluginCompletion", "Sample plugin")] : [];
}

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
	public var lastApi(default, null):Null<EditorApi>;

	public function new() {}

	public function id():String
		return "sample";

	public function activate(context:PluginContext):Void {
		activations++;
		lastApi = context.api;
		context.addSyntax(BuiltinSyntax.definition("Sample", [".sample"], ["sample"], [], []));
		context.addCommand("sample:run", function(editor:CommandContext) {
			this.performed++;
			context.api.replaceSelections("plugin");
		});
		context.bind(77, 3, ["sample:run"]);
		context.api.addPanel("status", "Sample", "ready");
		context.api.addStatusItem("mode", "Sample Ready", 10);
		context.api.addDecoration("first-word", 0, 0, 1, 0x224488FF);
		context.api.onDocumentChanged(function(event) {
			this.events++;
			context.api.setPanelText("status", event.document.buffer.text);
		});
		context.api.schedule(job);
		context.addCompletionProvider(new SampleCompletionProvider());
	}

	public function deactivate(context:PluginContext):Void
		deactivations++;

	public function refresh():Bool
		return false;

	public function update(now:Float):Bool
		return false;

	public function diagnostic():Null<String>
		return null;

	public function requestRefresh():Bool
		return false;

	public function dispose():Void {}
}

class BrokenPlugin implements Plugin {
	public function new() {}

	public function id():String
		return "broken";

	public function activate(context:PluginContext):Void {
		context.addCommand("broken:leak", function(editor:CommandContext) {});
		context.api.addStatusItem("leak", "broken");
		context.api.addDecoration("leak", 0, 0, 1, 0xFFFFFFFF);
		context.bind(1, 0, ["root:close"]);
	}

	public function deactivate(context:PluginContext):Void {}

	public function refresh():Bool
		return false;

	public function update(now:Float):Bool
		return false;

	public function diagnostic():Null<String>
		return null;

	public function requestRefresh():Bool
		return false;

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
		require(plugin.activations == 1 && application.plugins.isLoaded("sample") && application.completions.count() == 2,
			"plugin activation state or completion contribution was not recorded");
		require(application.syntaxes.find("file.sample").name == "Sample", "plugin syntax did not register");
		require(!application.plugins.load(new SamplePlugin()), "duplicate plugin id was accepted");
		require(application.keyPressed(77, 3) && plugin.performed == 1 && plugin.events == 1
			&& application.context.requireDocument().buffer.text == "plugin", "plugin command did not perform an owned document transaction");
		require(application.commands.perform("doc:complete-word", application.context)
			&& application.root.commandView.results.length == 1
			&& application.root.commandView.results[0].value == "pluginCompletion", "plugin completion provider did not contribute to word completion");
		application.keyPressed(Platform.KEY_ESCAPE, 0);
		var panel = application.root.pluginPanels.find("sample", "status");
		require(panel != null && panel.text == "plugin", "plugin panel or document event contribution was not live");
		require(application.root.pluginStatusItems.find("sample", "mode") != null
			&& application.root.status.text(application.context.requireView()).indexOf("Sample Ready") >= 0
			&& application.root.pluginDecorations.find("sample", "first-word") != null,
			"plugin status item or editor decoration was not live");
		application.openCommandView();
		application.textInput("samplerun");
		require(application.root.commandView.results.length == 1, "plugin command was absent from command view");
		application.keyPressed(Platform.KEY_ENTER, 0);
		require(plugin.performed == 2, "plugin command palette entry did not dispatch");
		require(application.commands.perform("plugins:disable", application.context)
			&& application.root.commandView.results.length == 1, "plugin disable picker did not open");
		application.keyPressed(Platform.KEY_ENTER, 0);
		require(plugin.deactivations == 1 && !application.commands.contains("sample:run") && !application.keyPressed(77, 3),
			"plugin registrations survived disable");
		require(application.completions.count() == 1, "plugin completion provider survived disable");
		var eventsAfterUnload = plugin.events;
		application.textInput("after");
		require(application.root.pluginPanels.find("sample", "status") == null && plugin.events == eventsAfterUnload && plugin.job.cancelled,
			"plugin panel, event subscription, or scheduled job survived disable");
		require(application.root.pluginStatusItems.find("sample", "mode") == null
			&& application.root.pluginDecorations.find("sample", "first-word") == null,
			"plugin status item or editor decoration survived disable");
		var staleApiRejected = false;
		try plugin.lastApi.addStatusItem("stale", "leak") catch (error:Dynamic) staleApiRejected = true;
		require(staleApiRejected && application.root.pluginStatusItems.find("sample", "stale") == null,
			"retired plugin API accepted or leaked a new contribution");
		require(application.syntaxes.find("file.sample").name == "Plain Text", "plugin syntax survived disable");
		require(!application.plugins.isLoaded("sample") && application.plugins.disabledIds().indexOf("sample") >= 0,
			"disabled plugin definition was not retained");
		require(application.commands.perform("plugins:enable", application.context)
			&& application.root.commandView.results.length == 1, "plugin enable picker did not open");
		application.keyPressed(Platform.KEY_ENTER, 0);
		require(plugin.activations == 2 && application.plugins.isLoaded("sample"),
			"plugin did not enable with fresh registrations");
		require(application.commands.perform("plugins:reload", application.context)
			&& application.root.commandView.results.length == 1, "plugin reload picker did not open");
		application.keyPressed(Platform.KEY_ENTER, 0);
		require(plugin.activations == 3, "plugin did not reload");
		var activeView = application.context.requireView(), activeDocument = application.context.requireDocument(), activeSelection = activeView.getSelection();
		require(activeSelection != null, "document view did not expose its selection");
		activeDocument.buffer.replaceAllText("alpha alphabet al", activeSelection);
		activeSelection.setCursor(activeDocument.buffer, activeDocument.buffer.endPosition());
		require(application.commands.perform("doc:complete-word", application.context)
			&& application.root.commandView.results.length == 2, "built-in word completion did not open through the shared registry");
		application.keyPressed(Platform.KEY_ENTER, 0);
		require(activeDocument.buffer.text == "alpha alphabet alpha", "completion acceptance did not replace the typed prefix");
		var failed = false;
		try {
			application.plugins.load(new BrokenPlugin());
		} catch (error:Dynamic) {
			failed = true;
		}
		require(failed
			&& !application.plugins.isLoaded("broken")
			&& !application.commands.contains("broken:leak")
			&& application.root.pluginStatusItems.find("broken", "leak") == null
			&& application.root.pluginDecorations.find("broken", "leak") == null, "failed activation leaked plugin state");
		application.shutdown();
		require(plugin.deactivations == 3 && application.plugins.count() == 0, "application shutdown did not deactivate plugins");
		renderer.destroy();
		Platform.require(Native.window_destroy(window), "destroy plugin test window");
		Native.shutdown();
		Sys.println("PASS: plugin activation, palette dispatch, rollback, reload, and cleanup");
		return 0;
	}
}
