package app;

import editor.TextBuffer;
import editor.Document;
import editor.BufferPosition;

class DocumentTestMain {
	static function require(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function main():Int {
		var buffer = new TextBuffer("alpha\nbeta");
		require(buffer.lineCount() == 2 && buffer.line(1) == "beta", "line indexing failed");
		buffer.setCursor(new BufferPosition(0, 5));
		buffer.insert("!");
		require(buffer.text == "alpha!\nbeta" && buffer.cursor.equals(new BufferPosition(0, 6)), "insertion failed");
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
		require(buffer.text == "replacement" && buffer.cursor.equals(new BufferPosition(0, 11)), "select-all replacement failed");
		var vertical = new TextBuffer("abcdef\nxy\n123456");
		vertical.setCursor(vertical.positionAt(0, 5));
		vertical.moveVertical(1);
		require(vertical.cursor.equals(new BufferPosition(1, 2)), "vertical movement did not clamp to short line");
		vertical.moveVertical(1);
		require(vertical.cursor.equals(new BufferPosition(2, 5)), "vertical movement did not preserve preferred column");
		vertical.moveVertical(-1, true);
		require(vertical.hasSelection() && vertical.cursor.column == 2, "vertical selection failed");
		var multiline = new TextBuffer("one\ntwo\nthree"), cleanState = multiline.stateId;
		multiline.setCursor(new BufferPosition(0, 2));
		multiline.insert("X\nY");
		require(multiline.lineCount() == 4 && multiline.line(0) == "onX" && multiline.line(1) == "Ye", "line splice insertion failed");
		require(multiline.undo() && multiline.text == "one\ntwo\nthree" && multiline.stateId == cleanState, "range undo failed");
		require(multiline.redo() && multiline.text == "onX\nYe\ntwo\nthree", "range redo failed");
		var unicode = new TextBuffer("A😀B");
		unicode.setCursor(new BufferPosition(0, 1));
		unicode.move(1);
		require(unicode.cursor.column == 3, "cursor split a surrogate pair");
		unicode.deleteBackward();
		require(unicode.text == "AB" && unicode.cursor.column == 1, "backspace split a surrogate pair");
		var document = new Document("unused", "clean");
		document.insert(" edit");
		require(document.dirty && document.buffer.text == " editclean", "document dirty state failed");
		document.undo();
		require(!document.dirty && document.buffer.text == "clean", "undo did not restore document savepoint");
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
