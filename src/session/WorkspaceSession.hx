package session;

import core.Application;
import sys.FileSystem;
import sys.io.File;

class WorkspaceSession {
	public static inline final VERSION = 1;
	public final projects:Array<String> = [];
	public final documents:Array<String> = [];
	public var activeDocument:String = "";
	public var sidebar:String = "project";
	public final layout:Array<String> = [];
	public final expanded:Array<String> = [];

	public function new() {}

	public static function capture(application:Application):WorkspaceSession {
		var result = new WorkspaceSession();
		for (project in application.workspace.projects) {
			result.projects.push(project.root);
			for (path in project.expandedPaths()) result.expanded.push(path);
		}
		for (document in application.documents.documents)
			if (FileSystem.exists(document.path) && !FileSystem.isDirectory(document.path)) result.documents.push(document.path);
		var view = application.context.activeView();
		if (view != null) {
			var active = view.getDocument();
			if (active != null) result.activeDocument = active.path;
		}
		result.sidebar = application.root.searchVisible ? "search" : "project";
		for (line in application.root.sessionLines()) result.layout.push(line);
		return result;
	}

	public function restore(application:Application):Void {
		for (root in projects)
			if (FileSystem.exists(root) && FileSystem.isDirectory(root)) application.openArgument(root);
		for (project in application.workspace.projects) project.restoreExpanded(expanded);
		if (layout.length > 0) application.root.restoreSessionLines(layout); else {
			for (path in documents)
				if (FileSystem.exists(path) && !FileSystem.isDirectory(path)) application.open(path);
			if (activeDocument.length > 0 && FileSystem.exists(activeDocument) && !FileSystem.isDirectory(activeDocument)) application.open(activeDocument);
		}
		if (sidebar == "project") application.root.showProjectSidebar(); else application.root.showSearchResults("", []);
	}

	public function encode():String {
		var output = "version=" + VERSION + "\n";
		for (project in projects) output += "project=" + clean(project) + "\n";
		for (document in documents) output += "document=" + clean(document) + "\n";
		output += "active=" + clean(activeDocument) + "\nsidebar=" + sidebar + "\n";
		for (line in layout) output += "layout=" + clean(line) + "\n";
		for (path in expanded) output += "expanded=" + clean(path) + "\n";
		return output;
	}

	public static function decode(content:String):WorkspaceSession {
		var result = new WorkspaceSession(), version = 0;
		for (raw in content.split("\n")) {
			var line = StringTools.endsWith(raw, "\r") ? raw.substring(0, raw.length - 1) : raw, separator = line.indexOf("=");
			if (line.length == 0 || separator < 0) continue;
			var key = line.substring(0, separator), value = line.substring(separator + 1);
			if (key == "version") version = Std.parseInt(value);
			else if (key == "project") result.projects.push(value);
			else if (key == "document") result.documents.push(value);
			else if (key == "active") result.activeDocument = value;
			else if (key == "sidebar" && (value == "project" || value == "search")) result.sidebar = value;
			else if (key == "layout") result.layout.push(value);
			else if (key == "expanded") result.expanded.push(value);
		}
		if (version != VERSION) throw "unsupported workspace session version";
		return result;
	}

	public static function load(path:String):Null<WorkspaceSession> {
		if (path.length == 0 || !FileSystem.exists(path) || FileSystem.isDirectory(path)) return null;
		try {
			return decode(File.getContent(path));
		} catch (error:Dynamic) {
			return null;
		}
	}

	public function save(path:String):Bool {
		if (path.length == 0 || !ensureParent(path)) return false;
		return sys.io.AtomicFile.write(path, encode());
	}

	static function clean(value:String):String {
		if (value.indexOf("\n") >= 0 || value.indexOf("\r") >= 0) throw "session value contains a newline";
		return value;
	}

	static function ensureParent(path:String):Bool {
		var separator = path.lastIndexOf("/");
		if (separator <= 0) return true;
		var parent = path.substring(0, separator);
		if (FileSystem.exists(parent)) return FileSystem.isDirectory(parent);
		if (!ensureParent(parent)) return false;
		FileSystem.createDirectory(parent);
		return FileSystem.exists(parent) && FileSystem.isDirectory(parent);
	}
}
