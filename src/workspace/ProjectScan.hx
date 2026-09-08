package workspace;

import jobs.JobTask;

class ProjectScan implements JobTask {
	public final generation:Int;
	public final tree:ProjectNode;
	public final files:Array<ProjectNode> = [];
	public var complete(default, null):Bool = false;
	public var snapshot(default, null):String = "";
	final owner:Project;
	final fileSystem:FileSystemService;
	final ignored:Map<String, Bool>;
	final directories:Array<ProjectNode>;
	final snapshotParts:Array<String> = [];
	final seen:Map<String, Bool> = [];
	var cursor:Int = 0;
	var cancelled:Bool = false;

	public function new(owner:Project, generation:Int, fileSystem:FileSystemService, ignored:Map<String, Bool>) {
		this.owner = owner;
		this.generation = generation;
		this.fileSystem = fileSystem;
		this.ignored = ignored;
		tree = new ProjectNode(owner.name, owner.root, true, 0, true);
		directories = [tree];
	}

	public function step():Bool {
		if (cancelled || complete) return true;
		if (cursor >= directories.length) {
			finish();
			return true;
		}
		var node = directories[cursor++];
		try {
			var identity = fileSystem.normalize(node.path);
			if (!seen.exists(identity)) {
				seen.set(identity, true);
				for (entry in fileSystem.entries(node.path)) if (!ignored.exists(entry)) {
					var path = fileSystem.join(node.path, entry), directory = fileSystem.isDirectory(path),
						child = new ProjectNode(entry, path, directory, node.depth + 1);
					node.children.push(child);
					snapshotParts.push(path);
					if (directory) directories.push(child); else files.push(child);
				}
			}
		} catch (error:Dynamic) {
			owner.scanFailed(generation, node.path, Std.string(error));
		}
		node.loaded = true;
		owner.publishScan(this, false);
		if (cursor >= directories.length) {
			finish();
			return true;
		}
		return false;
	}

	function finish():Void {
		snapshot = snapshotParts.join("\n") + (snapshotParts.length == 0 ? "" : "\n");
		complete = true;
		owner.publishScan(this, true);
	}

	public function cancel():Void cancelled = true;
}
