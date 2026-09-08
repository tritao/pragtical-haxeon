package plugin;

interface Plugin {
	function id():String;
	function activate(context:PluginContext):Void;
	function deactivate(context:PluginContext):Void;
	/** Performs cheap time-based observation; expensive refresh work is debounced. */
	function update(now:Float):Bool;
	/** Forces a source comparison and publication attempt. */
	function refresh():Bool;
	function diagnostic():Null<String>;
	function dispose():Void;
}
