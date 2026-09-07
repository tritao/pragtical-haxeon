package plugin;

import command.CommandContext;
import compiler.Compiler;
import compiler.Diagnostic.CompileError;
import compiler.hl.HlWriter;
import runtime.LoadedModule;
import runtime.PatchSet;
import runtime.Runtime;
import runtime.RuntimeError;
import sys.io.File;

class DynamicPlugin implements Plugin {
	public final manifest:PluginManifest;
	public var lastError(default, null):Null<String>;
	public var revision(default, null):Int = 0;

	final compiler:Compiler;
	final contents:Array<String> = [];
	var module:Null<LoadedModule>;
	var functionIds:Map<String, Int> = [];
	var context:Null<PluginContext>;

	public function new(manifest:PluginManifest) {
		this.manifest = manifest;
		compiler = new Compiler();
		compiler.enablePublicationTracking();
		for (source in manifest.sources) {
			var content = File.getContent(source);
			contents.push(content);
			compiler.update(modulePath(source), content);
		}
		var build = compilePlugin();
		module = Runtime.load(HlWriter.encode(build.module), build.runtimeIdentity);
		functionIds = build.functionIds;
		revision = build.revision;
		compiler.acknowledgePublication(build.revision);
	}

	public function id():String
		return manifest.id;

	public function activate(context:PluginContext):Void {
		this.context = context;
		Runtime.callVoid(requireModule(), functionId("activate"));
		for (command in manifest.commands) {
			var stableId = functionId(command.functionName);
			context.addCommand(command.name, function(editor:CommandContext) {
				Runtime.callVoid(requireModule(), stableId);
			});
			if (command.key > 0)
				context.bind(command.key, command.modifiers, [command.name]);
		}
	}

	public function deactivate(context:PluginContext):Void {
		Runtime.callVoid(requireModule(), functionId("deactivate"));
		this.context = null;
	}

	public function refresh():Bool {
		var changed = false;
		for (index in 0...manifest.sources.length) {
			var content = File.getContent(manifest.sources[index]);
			if (content != contents[index]) {
				contents[index] = content;
				compiler.update(modulePath(manifest.sources[index]), content);
				changed = true;
			}
		}
		if (!changed)
			return false;
		try {
			var build = compilePlugin();
			if (build.patchBytes != null && !build.requiresReload) {
				try {
					Runtime.patchSet(requireModule(), new PatchSet(revision, build.revision, build.patchBytes, build.changedFunctions));
					functionIds = build.functionIds;
					revision = build.revision;
					compiler.acknowledgePublication(build.revision);
				} catch (error:RuntimeError) {
					reload(build);
				}
			} else if (build.requiresReload) {
				reload(build);
			}
			lastError = null;
			return true;
		} catch (error:RuntimeError) {
			lastError = error.message;
			return false;
		} catch (error:Dynamic) {
			lastError = Std.string(error);
			return false;
		}
	}

	public function dispose():Void {
		var loaded = module;
		if (loaded != null)
			Runtime.dispose(loaded);
		module = null;
	}

	public function callInt(name:String):Int
		return Runtime.callInt(requireModule(), functionId(name));

	function compilePlugin():compiler.CompileResult {
		try {
			return compiler.compile(manifest.entry);
		} catch (error:CompileError) {
			var diagnostic = error.diagnostic;
			throw '${diagnostic.span.file.path}:${diagnostic.span.start}: ${diagnostic.code}: ${diagnostic.message}';
		}
	}

	function reload(build:compiler.CompileResult):Void {
		var previous = requireModule(),
			state = Runtime.callString(previous, functionId("saveState")),
			replacement = Runtime.load(HlWriter.encode(build.module), build.runtimeIdentity),
			nextIds = build.functionIds;
		try {
			Runtime.callVoid(previous, functionId("deactivate"));
			Runtime.callVoid(replacement, requiredId(nextIds, "activate"));
			Runtime.callStringArg(replacement, requiredId(nextIds, "restoreState"), state);
		} catch (error:Dynamic) {
			Runtime.dispose(replacement);
			Runtime.callVoid(previous, functionId("activate"));
			throw error;
		}
		module = replacement;
		functionIds = nextIds;
		revision = build.revision;
		compiler.acknowledgePublication(build.revision);
		Runtime.dispose(previous);
	}

	function functionId(name:String):Int
		return requiredId(functionIds, name);

	function requiredId(ids:Map<String, Int>, name:String):Int {
		if (ids.exists(name))
			return ids.get(name);
		var qualified = manifest.entry + "." + name;
		if (ids.exists(qualified))
			return ids.get(qualified);
		throw 'plugin is missing exported function "$qualified"';
	}

	function requireModule():LoadedModule {
		if (module == null)
			throw 'plugin "${manifest.id}" has no loaded module';
		return module;
	}

	static function modulePath(path:String):String {
		var slash = path.lastIndexOf("/"),
			name = slash < 0 ? path : path.substring(slash + 1);
		return name;
	}
}
