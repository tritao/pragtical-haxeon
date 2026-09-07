package plugin;

import sys.io.File;

class PluginManifest {
	public final path:String;
	public var id(default, null):String = "";
	public var version(default, null):String = "";
	public var entry(default, null):String = "Main";
	public final sources:Array<String> = [];
	public final commands:Array<DynamicCommand> = [];

	public function new(path:String) {
		this.path = path;
		parse(File.getContent(path));
		if (id.length == 0)
			throw 'plugin manifest "$path" has no id';
		if (sources.length == 0)
			throw 'plugin manifest "$path" has no sources';
	}

	function parse(content:String):Void {
		for (line in content.split("\n")) {
			var value = StringTools.trim(line);
			if (value.length == 0 || StringTools.startsWith(value, "#"))
				continue;
			var separator = value.indexOf("=");
			if (separator <= 0)
				throw 'invalid plugin manifest line: "$value"';
			var key = StringTools.trim(value.substring(0, separator)),
				setting = StringTools.trim(value.substring(separator + 1));
			if (key == "id")
				id = setting;
			else if (key == "version")
				version = setting;
			else if (key == "entry")
				entry = setting;
			else if (key == "source")
				sources.push(resolve(setting));
			else if (key == "command")
				parseCommand(setting);
			else
				throw 'unknown plugin manifest key "$key"';
		}
	}

	function parseCommand(value:String):Void {
		var fields = value.split("|");
		if (fields.length != 4)
			throw 'plugin command must be name|function|key|modifiers';
		commands.push(new DynamicCommand(fields[0], fields[1], Std.parseInt(fields[2]), Std.parseInt(fields[3])));
	}

	function resolve(value:String):String {
		if (StringTools.startsWith(value, "/"))
			return value;
		var separator = path.lastIndexOf("/");
		return separator < 0 ? value : path.substring(0, separator + 1) + value;
	}
}
