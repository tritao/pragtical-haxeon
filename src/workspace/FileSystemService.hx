package workspace;

import sys.FileSystem;

class FileSystemService {
	public function new() {}

	public function normalize(path:String):String {
		var value = StringTools.replace(FileSystem.fullPath(path), "\\", "/");
		while (value.length > 1 && StringTools.endsWith(value, "/")) value = value.substring(0, value.length - 1);
		return value;
	}

	public function exists(path:String):Bool
		return FileSystem.exists(path);

	public function isDirectory(path:String):Bool
		return FileSystem.isDirectory(path);

	public function entries(path:String):Array<String> {
		var values = FileSystem.readDirectory(path);
		values.sort(Reflect.compare);
		return values;
	}

	public function join(parent:String, name:String):String
		return parent + "/" + name;
}
