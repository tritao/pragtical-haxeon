package workspace;

class Project {
	public final root:String;
	public final name:String;
	public final tree:ProjectNode;
	public var settings:Null<config.SettingsService>;
	final fileSystem:FileSystemService;
	var ignored:Map<String, Bool> = [];
	var fileSnapshot:String = "";
	var scanQueue:Array<String> = [];
	var scanIndex:Int = 0;
	var scannedSnapshot:String = "";
	var scanSeen:Map<String, Bool> = [];
	public final diagnostics:Array<String> = [];

	public function new(path:String, fileSystem:FileSystemService, ?ignoredNames:Array<String>) {
		this.fileSystem = fileSystem;
		root = fileSystem.normalize(path);
		if (!fileSystem.exists(root) || !fileSystem.isDirectory(root)) throw 'project root is not a directory: "$root"';
		var separator = root.lastIndexOf("/");
		name = separator < 0 ? root : root.substring(separator + 1);
		tree = new ProjectNode(name, root, true, 0, true);
		setIgnored(ignoredNames == null ? [] : ignoredNames);
	}

	public function setIgnored(names:Array<String>):Void {
		ignored = [];
		for (name in [".git", ".hg", ".svn", ".devstack", "build", "out", "node_modules"]) ignored.set(name, true);
		for (name in names) ignored.set(name, true);
		tree.children.resize(0);
		tree.loaded = false;
		load(tree);
		fileSnapshot = "";
		startChangeScan();
	}

	public function pollChanges(directoryBudget:Int):Bool {
		if (settings != null && settings.reload()) setIgnored(settings.current.excludedNames);
		var processed = 0;
		while (scanIndex < scanQueue.length && processed < directoryBudget) {
			var path = scanQueue[scanIndex++];
			try {
				var identity = fileSystem.normalize(path);
				if (scanSeen.exists(identity)) continue;
				scanSeen.set(identity, true);
				for (entry in fileSystem.entries(path))
					if (!ignored.exists(entry)) {
						var child = fileSystem.join(path, entry);
						scannedSnapshot += child + "\n";
						if (fileSystem.isDirectory(child)) scanQueue.push(child);
					}
			} catch (error:Dynamic) { diagnostics.push('Could not scan "' + path + '"'); }
			processed++;
		}
		if (scanIndex < scanQueue.length) return false;
		var changed = scannedSnapshot != fileSnapshot;
		fileSnapshot = scannedSnapshot;
		if (changed) {
			var expanded = expandedPaths();
			tree.children.resize(0);
			tree.loaded = false;
			load(tree);
			restoreExpanded(expanded);
		}
		startChangeScan();
		return changed;
	}

	function startChangeScan():Void {
		scanQueue = [root];
		scanIndex = 0;
		scanSeen = [];
		scannedSnapshot = "";
	}

	public function load(node:ProjectNode):Void {
		if (!node.directory || node.loaded) return;
		for (entry in fileSystem.entries(node.path))
			if (!ignored.exists(entry)) {
				var path = fileSystem.join(node.path, entry), directory = fileSystem.isDirectory(path);
				node.children.push(new ProjectNode(entry, path, directory, node.depth + 1));
			}
		node.loaded = true;
	}

	public function toggle(node:ProjectNode):Void {
		if (!node.directory) return;
		load(node);
		node.toggle();
	}

	public function visibleNodes():Array<ProjectNode> {
		var result:Array<ProjectNode> = [];
		appendVisible(tree, result);
		return result;
	}

	public function files():Array<ProjectNode> {
		var result:Array<ProjectNode> = [];
		appendFiles(tree, result);
		return result;
	}

	public function expandedPaths():Array<String> {
		var result:Array<String> = [];
		appendExpanded(tree, result);
		return result;
	}

	public function restoreExpanded(paths:Array<String>):Void {
		for (path in paths) restoreExpandedPath(tree, path);
	}

	function appendExpanded(node:ProjectNode, result:Array<String>):Void {
		if (node.directory && node.expanded) result.push(node.path);
		if (node.directory && node.loaded) for (child in node.children) appendExpanded(child, result);
	}

	function restoreExpandedPath(node:ProjectNode, path:String):Bool {
		if (node.path == path) {
			load(node);
			if (!node.expanded) node.toggle();
			return true;
		}
		if (!node.directory || !StringTools.startsWith(path, node.path + "/")) return false;
		load(node);
		for (child in node.children) if (restoreExpandedPath(child, path)) return true;
		return false;
	}

	function appendFiles(node:ProjectNode, result:Array<ProjectNode>):Void {
		if (!node.directory) {
			result.push(node);
			return;
		}
		load(node);
		for (child in node.children) appendFiles(child, result);
	}

	function appendVisible(node:ProjectNode, result:Array<ProjectNode>):Void {
		result.push(node);
		if (node.directory && node.expanded)
			for (child in node.children) appendVisible(child, result);
	}
}
