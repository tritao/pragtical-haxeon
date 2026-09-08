package workspace;

class Project {
	public final root:String;
	public final name:String;
	public final tree:ProjectNode;
	final fileSystem:FileSystemService;
	var ignored:Map<String, Bool> = [];

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
