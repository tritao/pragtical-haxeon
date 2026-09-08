package recovery;

import core.Application;
import sys.FileSystem;
import workspace.FileSystemService;
import workspace.EditorFileSystem;

class RecoveryStore {
	public static inline final VERSION = 1;
	public final path:String;
	public final diagnostics:Array<String> = [];
	final fileSystem:EditorFileSystem;

	public function new(path:String, ?fileSystem:EditorFileSystem) {
		this.path = path;
		this.fileSystem = fileSystem == null ? new FileSystemService() : fileSystem;
	}

	public function save(application:Application):Bool {
		var snapshots = load();
		if (diagnostics.length > 0) return false;
		for (document in application.documents.documents) {
			if (!document.dirty) continue;
			var index = snapshots.length;
			while (index > 0) {
				index--;
				if (snapshots[index].path == document.path) snapshots.splice(index, 1);
			}
			snapshots.push(new RecoverySnapshot(document.path, document.buffer.text));
		}
		return saveSnapshots(snapshots);
	}

	public function saveSnapshots(snapshots:Array<RecoverySnapshot>):Bool {
		if (!ensureParent(path)) return false;
		var output = "pragtical-recovery=" + VERSION + "\n";
		for (snapshot in snapshots)
			output += snapshot.path.length + ":" + snapshot.text.length + ":" + snapshot.path + snapshot.text;
		return fileSystem.writeAtomic(path, output);
	}

	public function forget(sourcePath:String):Bool {
		var snapshots = load();
		if (diagnostics.length > 0) return false;
		return saveSnapshots([for (snapshot in snapshots) if (snapshot.path != sourcePath) snapshot]);
	}

	public function load():Array<RecoverySnapshot> {
		diagnostics.resize(0);
		if (!fileSystem.exists(path) || fileSystem.isDirectory(path)) return [];
		try {
			return decode(fileSystem.read(path));
		} catch (error:Dynamic) {
			diagnostics.push("Could not read recovery data: " + Std.string(error));
			return [];
		}
	}

	public static function decode(content:String):Array<RecoverySnapshot> {
		var marker = "pragtical-recovery=" + VERSION + "\n";
		if (!StringTools.startsWith(content, marker)) throw "unsupported recovery version";
		var result:Array<RecoverySnapshot> = [], offset = marker.length;
		while (offset < content.length) {
			var first = content.indexOf(":", offset), second = first < 0 ? -1 : content.indexOf(":", first + 1);
			if (first < 0 || second < 0) throw "corrupt recovery lengths";
			var pathLength = Std.parseInt(content.substring(offset, first)), textLength = Std.parseInt(content.substring(first + 1, second));
			if (Std.string(pathLength) != content.substring(offset, first) || Std.string(textLength) != content.substring(first + 1, second)) throw "corrupt recovery lengths";
			offset = second + 1;
			if (pathLength < 0 || textLength < 0 || offset + pathLength + textLength > content.length) throw "corrupt recovery payload";
			var recoveredPath = content.substr(offset, pathLength);
			offset += pathLength;
			var text = content.substr(offset, textLength);
			offset += textLength;
			result.push(new RecoverySnapshot(recoveredPath, text));
		}
		return result;
	}

	public function restore(application:Application, snapshot:RecoverySnapshot):Bool {
		if (!fileSystem.exists(snapshot.path) || fileSystem.isDirectory(snapshot.path)) {
			diagnostics.push('Recovery source is missing: "' + snapshot.path + '"');
			return false;
		}
		var document = application.documents.open(snapshot.path);
		document.acceptRecoveredText(snapshot.text);
		application.root.openDocument(document);
		return true;
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
