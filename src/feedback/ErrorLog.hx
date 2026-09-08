package feedback;

class ErrorLog {
	public final capacity:Int;
	public final entries:Array<ErrorEntry> = [];

	public function new(capacity:Int = 200) {
		if (capacity < 1) throw "error-log capacity must be positive";
		this.capacity = capacity;
	}

	public function record(source:String, message:String):ErrorEntry {
		var entry = new ErrorEntry(source, message, Sys.time());
		entries.push(entry);
		while (entries.length > capacity) entries.shift();
		return entry;
	}

	public function clear():Void
		entries.resize(0);
}
