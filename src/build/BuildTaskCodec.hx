package build;

class BuildTaskCodec {
	public static function parse(content:String):Array<BuildTask> {
		var tasks:Array<BuildTask> = [], current:Null<BuildTask> = null, lineNumber = 0;
		for (raw in content.split("\n")) {
			lineNumber++;
			var line = StringTools.trim(raw);
			if (line.length == 0 || StringTools.startsWith(line, "#")) continue;
			var separator = line.indexOf("=");
			if (separator <= 0) throw 'tasks.conf:$lineNumber: expected key=value';
			var key = StringTools.trim(line.substring(0, separator)), value = line.substring(separator + 1);
			if (key == "task") {
				if (value.length == 0) throw 'tasks.conf:$lineNumber: task name is empty';
				current = new BuildTask(value);
				tasks.push(current);
			} else {
				if (current == null) throw 'tasks.conf:$lineNumber: task must be declared first';
				if (key == "executable") current.executable = value;
				else if (key == "cwd") current.cwd = value;
				else if (key == "argument") current.arguments.push(value);
				else if (key == "environment") {
					var equals = value.indexOf("=");
					if (equals <= 0) throw 'tasks.conf:$lineNumber: environment requires NAME=value';
					current.environment.set(value.substring(0, equals), value.substring(equals + 1));
				} else throw 'tasks.conf:$lineNumber: unknown key "$key"';
			}
		}
		var names:Map<String, Bool> = [];
		for (task in tasks) {
			if (task.executable.length == 0) throw 'task "${task.name}" has no executable';
			if (names.exists(task.name)) throw 'duplicate task "${task.name}"';
			names.set(task.name, true);
		}
		return tasks;
	}
}
