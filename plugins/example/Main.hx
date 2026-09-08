import pragtical.Editor;

class PluginState {
	public static var value = 0;
	public static var events = 0;
}

function main():Int
	return 0;

function activate():Void {
	Editor.connect("example");
	Editor.addPanel("status", "Example Plugin", "ready");
	Editor.addStatusItem("mode", "Example Ready", "5");
	Editor.addDecoration("first-character", "0:0:1", "574920959");
	Editor.onDocumentChanged("documentChanged");
}
function deactivate():Void {}

function saveState():String
	return PluginState.value == 0 ? "0" : PluginState.value == 1 ? "1" : PluginState.value == 3 ? "3" : "0";

function stateVersion():Int
	return 1;

function restoreState(value:String):Void {
	PluginState.value = value == "1" ? 1 : value == "3" ? 3 : 0;
}

function increment():Void {
	PluginState.value = PluginState.value + 1;
	Editor.replaceSelections("dynamic");
}

function documentChanged(text:String):Void {
	PluginState.events++;
	Editor.setPanelText("status", text);
}

function current():Int
	return PluginState.value;

function eventCount():Int
	return PluginState.events;

function hostProbe():Int
	return Editor.replaceSelections("probe") ? 42 : 0;
