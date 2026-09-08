package plugin;

import command.CommandContext;
import command.CommandRegistry;
import command.Keymap;
import syntax.SyntaxRegistry;
import config.Settings;
import jobs.JobScheduler;

class PluginManager {
	final commands:CommandRegistry;
	final keymap:Keymap;
	final commandContext:CommandContext;
	final syntaxes:SyntaxRegistry;
	final panels:PluginPanelRegistry;
	final jobs:JobScheduler;
	final settings:Void->Settings;
	final reportDiagnostic:String->Void;
	final entries:Array<PluginEntry> = [];
	final reportedDiagnostics:Map<String, String> = [];

	public function new(commands:CommandRegistry, keymap:Keymap, commandContext:CommandContext, syntaxes:SyntaxRegistry,
			panels:PluginPanelRegistry, jobs:JobScheduler, settings:Void->Settings, ?reportDiagnostic:String->Void) {
		this.commands = commands;
		this.keymap = keymap;
		this.commandContext = commandContext;
		this.syntaxes = syntaxes;
		this.panels = panels;
		this.jobs = jobs;
		this.settings = settings;
		this.reportDiagnostic = reportDiagnostic == null ? function(message:String) {} : reportDiagnostic;
		DynamicHostRouter.initialize();
	}

	public function load(plugin:Plugin):Bool {
		var id = plugin.id();
		if (!validId(id))
			throw 'invalid plugin id "$id"';
		if (indexOf(id) >= 0)
			return false;
		var context = new PluginContext(id, commands, keymap, commandContext, syntaxes, panels, jobs, settings);
		try {
			plugin.activate(context);
		} catch (error:Dynamic) {
			context.dispose();
			throw error;
		}
		entries.push(new PluginEntry(plugin, context));
		reportedDiagnostics.remove(id);
		return true;
	}

	public function unload(id:String):Bool {
		var index = indexOf(id);
		if (index < 0)
			return false;
		var entry = entries[index], plugin = entry.plugin, context = entry.context, failed = false, failure = "";
		try {
			plugin.deactivate(context);
		} catch (error:Dynamic) {
			failed = true;
			failure = Std.string(error);
		}
		context.dispose();
		entries.remove(entry);
		reportedDiagnostics.remove(id);
		plugin.dispose();
		if (failed)
			throw failure;
		return true;
	}

	public function reload(plugin:Plugin):Bool {
		unload(plugin.id());
		return load(plugin);
	}

	public function update(now:Float):Void {
		for (entry in entries) {
			entry.plugin.update(now);
			var id = entry.plugin.id(), diagnostic = entry.plugin.diagnostic();
			if (diagnostic == null) {
				reportedDiagnostics.remove(id);
			} else if (!reportedDiagnostics.exists(id) || reportedDiagnostics.get(id) != diagnostic) {
				reportedDiagnostics.set(id, diagnostic);
				reportDiagnostic('Plugin "$id": $diagnostic');
			}
		}
	}

	public function diagnostics():Array<String> {
		var values:Array<String> = [];
		for (id => message in reportedDiagnostics) values.push('$id: $message');
		values.sort(Reflect.compare);
		return values;
	}

	public function shutdown():Void {
		var index = entries.length, failed = false, failure = "";
		while (index > 0) {
			index--;
			try {
				unload(entries[index].plugin.id());
			} catch (error:Dynamic) {
				if (!failed) {
					failed = true;
					failure = Std.string(error);
				}
			}
		}
		if (failed)
			throw failure;
	}

	public function isLoaded(id:String):Bool
		return indexOf(id) >= 0;

	public function count():Int
		return entries.length;

	function indexOf(id:String):Int {
		for (index in 0...entries.length)
			if (entries[index].plugin.id() == id)
				return index;
		return -1;
	}

	static function validId(id:String):Bool
		return id.length > 0 && id.indexOf(":") < 0 && id.indexOf(" ") < 0;
}
