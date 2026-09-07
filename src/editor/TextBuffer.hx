package editor;

class TextBuffer {
	public var text(default, null):String;
	public var cursor(default, null):Int;
	public var anchor(default, null):Int;
	final undoStack:Array<BufferSnapshot> = [];
	final redoStack:Array<BufferSnapshot> = [];

	public function new(?text:String) {
		this.text = text == null ? "" : text;
		cursor = 0;
		anchor = 0;
	}

	public function hasSelection():Bool
		return cursor != anchor;

	public function selectionStart():Int
		return cursor < anchor ? cursor : anchor;

	public function selectionEnd():Int
		return cursor > anchor ? cursor : anchor;

	public function setCursor(position:Int, extend:Bool = false):Void {
		cursor = clamp(position);
		if (!extend)
			anchor = cursor;
	}

	public function move(delta:Int, extend:Bool = false):Void
		setCursor(cursor + delta, extend);

	public function selectAll():Void {
		anchor = 0;
		cursor = text.length;
	}

	public function selectedText():String
		return hasSelection() ? text.substring(selectionStart(), selectionEnd()) : "";

	public function insert(value:String):Void {
		if (value.length == 0 && !hasSelection())
			return;
		beginEdit();
		var start = selectionStart(), end = selectionEnd();
		text = text.substring(0, start) + value + text.substring(end);
		cursor = start + value.length;
		anchor = cursor;
	}

	public function deleteBackward():Void {
		if (hasSelection()) {
			insert("");
			return;
		}
		if (cursor == 0)
			return;
		beginEdit();
		text = text.substring(0, cursor - 1) + text.substring(cursor);
		cursor--;
		anchor = cursor;
	}

	public function deleteForward():Void {
		if (hasSelection()) {
			insert("");
			return;
		}
		if (cursor == text.length)
			return;
		beginEdit();
		text = text.substring(0, cursor) + text.substring(cursor + 1);
		anchor = cursor;
	}

	public function undo():Bool {
		var snapshot = undoStack.pop();
		if (snapshot == null)
			return false;
		redoStack.push(currentSnapshot());
		restore(snapshot);
		return true;
	}

	public function redo():Bool {
		var snapshot = redoStack.pop();
		if (snapshot == null)
			return false;
		undoStack.push(currentSnapshot());
		restore(snapshot);
		return true;
	}

	public function lineCount():Int
		return text.length == 0 ? 1 : text.split("\n").length;

	public function line(index:Int):String {
		var lines = text.split("\n");
		return index < 0 || index >= lines.length ? "" : lines[index];
	}

	public function cursorLine():Int
		return text.substring(0, cursor).split("\n").length - 1;

	public function cursorColumn():Int {
		var before = text.substring(0, cursor), separator = before.lastIndexOf("\n");
		return separator < 0 ? cursor : cursor - separator - 1;
	}

	public function moveHome(extend:Bool = false):Void {
		var before = text.substring(0, cursor), separator = before.lastIndexOf("\n");
		setCursor(separator < 0 ? 0 : separator + 1, extend);
	}

	public function moveEnd(extend:Bool = false):Void {
		var separator = text.indexOf("\n", cursor);
		setCursor(separator < 0 ? text.length : separator, extend);
	}

	function beginEdit():Void {
		undoStack.push(currentSnapshot());
		redoStack.resize(0);
	}

	function currentSnapshot():BufferSnapshot
		return new BufferSnapshot(text, cursor, anchor);

	function restore(snapshot:BufferSnapshot):Void {
		text = snapshot.text;
		cursor = snapshot.cursor;
		anchor = snapshot.anchor;
	}

	function clamp(position:Int):Int
		return position < 0 ? 0 : position > text.length ? text.length : position;
}
