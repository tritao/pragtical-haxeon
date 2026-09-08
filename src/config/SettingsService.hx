package config;

import sys.FileSystem;
import sys.io.File;

class SettingsService {
	public var current(default, null):Settings;
	public final diagnostics:Array<String> = [];
	public final layers:Array<SettingsLayer> = [];
	final listeners:Array<Settings->Void> = [];

	public function new(?userPath:String, ?projectPath:String) {
		current = new Settings();
		if (userPath != null && userPath.length > 0) layers.push(new SettingsLayer("user", userPath));
		if (projectPath != null && projectPath.length > 0) layers.push(new SettingsLayer("project", projectPath));
		reload(true);
	}

	public function setProject(path:String):Bool {
		var index = layers.length;
		while (index > 0) {
			index--;
			if (layers[index].name == "project") layers.splice(index, 1);
		}
		layers.push(new SettingsLayer("project", path));
		return reload(true);
	}

	public function forProject(path:String):SettingsService {
		var userPath = "";
		for (layer in layers) if (layer.name == "user") userPath = layer.path;
		return new SettingsService(userPath, path);
	}

	public function subscribe(listener:Settings->Void):Void->Void {
		listeners.push(listener);
		listener(current);
		var active = true;
		return function() {
			if (!active) return;
			active = false;
			listeners.remove(listener);
		};
	}

	public function unsubscribe(listener:Settings->Void):Void
		listeners.remove(listener);

	public function reload(force:Bool = false):Bool {
		var changed = force, contents:Array<String> = [], readErrors:Array<String> = [];
		for (layer in layers) {
			var content = "";
			try {
				if (FileSystem.exists(layer.path)) {
					if (FileSystem.isDirectory(layer.path)) readErrors.push(layer.path + ": settings path is a directory");
					else content = File.getContent(layer.path);
				}
			} catch (error:Dynamic) {
				readErrors.push(layer.path + ": could not read settings: " + Std.string(error));
			}
			contents.push(content);
			if (content != layer.content) changed = true;
		}
		if (readErrors.length > 0) {
			diagnostics.resize(0);
			for (error in readErrors) diagnostics.push(error);
			return false;
		}
		if (!changed) return false;
		var candidate = new Settings(), errors:Array<String> = [];
		for (index in 0...layers.length)
			if (contents[index].length > 0)
				for (error in SettingsCodec.apply(contents[index], candidate, layers[index].path)) errors.push(error);
		diagnostics.resize(0);
		for (error in errors) diagnostics.push(error);
		for (index in 0...layers.length) layers[index].content = contents[index];
		if (errors.length > 0) return false;
		current = candidate;
		for (listener in listeners.copy())
			if (listeners.indexOf(listener) >= 0) listener(current);
		return true;
	}
}
