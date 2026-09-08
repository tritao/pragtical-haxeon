package feedback;

class NotificationCenter {
	public final capacity:Int;
	public final entries:Array<Notification> = [];

	public function new(capacity:Int = 100) {
		if (capacity < 1) throw "notification capacity must be positive";
		this.capacity = capacity;
	}

	public function publish(message:String, kind:NotificationKind = Information):Notification {
		var entry = new Notification(message, kind, Sys.time());
		entries.push(entry);
		while (entries.length > capacity) entries.shift();
		return entry;
	}

	public function current():Null<Notification>
		return entries.length == 0 ? null : entries[entries.length - 1];

	public function clear():Void
		entries.resize(0);
}
