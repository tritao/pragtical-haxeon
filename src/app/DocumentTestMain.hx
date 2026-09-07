package app;

import editor.TextBuffer;
import editor.Document;

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
		var vertical = new TextBuffer("abcdef\nxy\n123456");
		vertical.setCursor(vertical.positionAt(0, 5));
		vertical.moveVertical(1);
		require(vertical.cursorLine() == 1 && vertical.cursorColumn() == 2, "vertical movement did not clamp to short line");
		vertical.moveVertical(1);
		require(vertical.cursorLine() == 2 && vertical.cursorColumn() == 5, "vertical movement did not preserve preferred column");
		vertical.moveVertical(-1, true);
		require(vertical.hasSelection() && vertical.cursorColumn() == 2, "vertical selection failed");
		var document = new Document("unused", "clean");
		document.insert(" edit");
		require(document.dirty && document.buffer.text == " editclean", "document dirty state failed");
		var arguments = Sys.args();
		if (arguments.length > 0) {
			var saved = new Document(arguments[0], "saved by Haxeon\n");
			saved.insert("!");
			saved.save();
			require(!saved.dirty && Document.open(arguments[0]).buffer.text == "!saved by Haxeon\n", "document save failed");
		}
		Sys.println("PASS: Haxeon text buffer editing, selections, and history");
		return 0;
	}
}
