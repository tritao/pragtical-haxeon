package commandview;

import editor.BufferSelection;
import editor.TextBuffer;
import platform.Native;

class CommandInput {
	public var buffer(default, null):TextBuffer;
	public var selection(default, null):BufferSelection;
	final history:Array<String> = [];
	var historyIndex:Int = 0;
	var draft:String = "";

	public function new() reset();

	public var text(get, never):String;
	function get_text():String return buffer.text;

	public function reset():Void {
		buffer = new TextBuffer();
		selection = new BufferSelection();
		historyIndex = history.length;
		draft = "";
	}

	public function setText(value:String):Void {
		selection.selectAll(buffer);
		buffer.replaceSelections(selection, [value]);
		buffer.breakHistoryGroup();
	}

	public function insert(value:String):Bool return buffer.insert(selection, value, value.indexOf("\n") < 0);
	public function backspace():Bool return buffer.deleteBackward(selection);
	public function deleteForward():Bool return buffer.deleteForward(selection);
	public function undo():Bool return buffer.undo(selection);
	public function redo():Bool return buffer.redo(selection);
	public function selectAll():Void selection.selectAll(buffer);
	public function move(delta:Int, extend:Bool):Void selection.move(buffer, delta, extend);
	public function moveWord(delta:Int, extend:Bool):Void selection.moveWord(buffer, delta, extend);
	public function moveHome(extend:Bool):Void selection.moveDocumentStart(buffer, extend);
	public function moveEnd(extend:Bool):Void selection.moveDocumentEnd(buffer, extend);

	public function copy():Bool
		return selection.hasSelection() && Native.clipboard_set(selection.selectedText(buffer));

	public function cut():Bool
		return copy() && buffer.insert(selection, "");

	public function paste():Bool {
		var value = Native.clipboard_get();
		value = StringTools.replace(StringTools.replace(value, "\r\n", "\n"), "\r", "\n");
		value = StringTools.replace(value, "\n", " ");
		return buffer.insert(selection, value);
	}

	public function remember():Void {
		var value = text;
		if (value.length > 0 && (history.length == 0 || history[history.length - 1] != value)) history.push(value);
		historyIndex = history.length;
		draft = "";
	}

	public function moveHistory(delta:Int):Bool {
		if (history.length == 0) return false;
		if (historyIndex == history.length) draft = text;
		historyIndex += delta;
		if (historyIndex < 0) historyIndex = 0;
		if (historyIndex > history.length) historyIndex = history.length;
		setText(historyIndex == history.length ? draft : history[historyIndex]);
		return true;
	}
}
