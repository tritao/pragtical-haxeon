package app;

import editor.TextBuffer;

class DocumentTestMain {
	static function require(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function main():Int {
		var buffer = new TextBuffer("alpha\nbeta");
		require(buffer.lineCount() == 2 && buffer.line(1) == "beta", "line indexing failed");
		buffer.setCursor(5);
		buffer.insert("!");
		require(buffer.text == "alpha!\nbeta" && buffer.cursor == 6, "insertion failed");
		buffer.move(-5, true);
		require(buffer.selectedText() == "lpha!", "selection failed");
		buffer.insert("L");
		require(buffer.text == "aL\nbeta" && !buffer.hasSelection(), "selection replacement failed");
		buffer.deleteBackward();
		require(buffer.text == "a\nbeta", "backspace failed");
		buffer.deleteForward();
		require(buffer.text == "abeta", "forward delete failed");
		require(buffer.undo() && buffer.text == "a\nbeta", "undo delete failed");
		require(buffer.undo() && buffer.text == "aL\nbeta", "undo backspace failed");
		require(buffer.redo() && buffer.text == "a\nbeta", "redo failed");
		buffer.selectAll();
		buffer.insert("replacement");
		require(buffer.text == "replacement" && buffer.cursor == 11, "select-all replacement failed");
		Sys.println("PASS: Haxeon text buffer editing, selections, and history");
		return 0;
	}
}
