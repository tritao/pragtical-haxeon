class PluginState {
	public static var value = 0;
}

function main():Int
	return 0;

function activate():Void {}
function deactivate():Void {}

function saveState():String
	return PluginState.value == 0 ? "0" : PluginState.value == 1 ? "1" : PluginState.value == 3 ? "3" : "0";

function restoreState(value:String):Void {
	PluginState.value = value == "1" ? 1 : value == "3" ? 3 : 0;
}

function increment():Void
	PluginState.value = PluginState.value + 1;

function current():Int
	return PluginState.value;
