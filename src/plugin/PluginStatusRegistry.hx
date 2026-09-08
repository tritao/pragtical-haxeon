package plugin;

class PluginStatusRegistry {
	final values:Array<PluginStatusItem> = [];

	public function new() {}

	public function add(owner:String, id:String, text:String, priority:Int = 0):PluginStatusItem {
		if (id.length == 0) throw "status item id cannot be empty";
		if (find(owner, id) != null) throw 'status item "$owner:$id" is already registered';
		var value = new PluginStatusItem(owner, id, text, priority);
		values.push(value);
		return value;
	}

	public function find(owner:String, id:String):Null<PluginStatusItem> {
		for (value in values) if (value.owner == owner && value.id == id) return value;
		return null;
	}

	public function items():Array<PluginStatusItem> {
		var result = values.copy();
		result.sort(function(a, b) {
			var order = b.priority - a.priority;
			return order == 0 ? Reflect.compare(a.owner + ":" + a.id, b.owner + ":" + b.id) : order;
		});
		return result;
	}

	public function remove(value:PluginStatusItem):Bool return values.remove(value);
	public function removeOwner(owner:String):Void {
		var index = values.length;
		while (index > 0) {
			index--;
			if (values[index].owner == owner) values.splice(index, 1);
		}
	}
}
