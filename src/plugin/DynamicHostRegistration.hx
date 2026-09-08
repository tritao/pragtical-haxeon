package plugin;

class DynamicHostRegistration {
	public final token:Int;
	public final context:PluginContext;
	public final plugin:DynamicPlugin;

	public function new(token:Int, context:PluginContext, plugin:DynamicPlugin) {
		this.token = token;
		this.context = context;
		this.plugin = plugin;
	}
}
