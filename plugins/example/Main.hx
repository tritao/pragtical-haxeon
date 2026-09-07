class PluginState {
	public static var value = 0;
}

function main():Int
	return 0;

function activate():Void {}
function deactivate():Void {}

function saveState():String
	return "";

function restoreState(value:String):Void {
	PluginState.value = 0;
}

function increment():Void
	PluginState.value = PluginState.value + 1;

function current():Int
	return PluginState.value;
