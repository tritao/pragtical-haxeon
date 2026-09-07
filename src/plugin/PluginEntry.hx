package plugin;

class PluginEntry {
	public final plugin:Plugin;
	public final context:PluginContext;

	public function new(plugin:Plugin, context:PluginContext) {
		this.plugin = plugin;
		this.context = context;
	}
}
