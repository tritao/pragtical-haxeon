package plugin;

interface Plugin {
	function id():String;
	function activate(context:PluginContext):Void;
	function deactivate(context:PluginContext):Void;
	function refresh():Bool;
	function dispose():Void;
}
