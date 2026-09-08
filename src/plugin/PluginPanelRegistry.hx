package plugin;

class PluginPanelRegistry {
	final registered:Array<PluginPanel> = [];

	public function new() {}

	public function add(owner:String, id:String, title:String, text:String):PluginPanel {
		if (id.length == 0 || title.length == 0) throw "plugin panels require an id and title";
		if (find(owner, id) != null) throw 'plugin panel "$owner:$id" is already registered';
		var panel = new PluginPanel(owner, id, title, text);
		registered.push(panel);
		return panel;
	}

	public function find(owner:String, id:String):Null<PluginPanel> {
		for (panel in registered) if (panel.owner == owner && panel.id == id) return panel;
		return null;
	}

	public function remove(panel:PluginPanel):Void
		registered.remove(panel);

	public function removeOwner(owner:String):Void {
		var index = registered.length;
		while (index > 0) {
			index--;
			if (registered[index].owner == owner) registered.splice(index, 1);
		}
	}

	public function panels():Array<PluginPanel>
		return registered.copy();
}
