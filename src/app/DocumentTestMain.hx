package app;

import editor.TextBuffer;
import editor.Document;
import editor.BufferPosition;
import editor.BufferSelection;
import syntax.HighlightToken;
import syntax.BuiltinSyntax;
import syntax.SyntaxRegistry;
import search.DocumentSearch;
import search.SearchOptions;
import editor.ExternalState;
import sys.io.File;
import haxe.io.Bytes;
import sys.FileSystem;
import workspace.FileSystemService;
import workspace.EditorFileSystem;
import core.DocumentManager;

class FailingFileSystem implements EditorFileSystem {
	final delegate = new FileSystemService();
	public function new() {}
	public function normalize(path:String):String return delegate.normalize(path);
	public function exists(path:String):Bool return delegate.exists(path);
	public function isDirectory(path:String):Bool return delegate.isDirectory(path);
	public function entries(path:String):Array<String> return delegate.entries(path);
	public function join(parent:String, name:String):String return delegate.join(parent, name);
	public function read(path:String):String return delegate.read(path);
	public function writeAtomic(path:String, content:String):Bool return false;
	public function createFile(path:String):Bool return delegate.createFile(path);
	public function createFolder(path:String):Bool return delegate.createFolder(path);
	public function rename(path:String, destination:String):Bool return delegate.rename(path, destination);
	public function deleteFile(path:String):Bool return delegate.deleteFile(path);
}

class DocumentTestMain {
	static function require(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function main():Int {
		var syntaxes = new SyntaxRegistry();
		BuiltinSyntax.install(syntaxes);
		require(syntaxes.find("script", "#!/usr/bin/env lua\n").name == "Lua" && syntaxes.find("data.json").name == "JSON"
			&& syntaxes.find("README.md").name == "Markdown", "built-in syntax selection failed");
		var buffer = new TextBuffer("alpha\nbeta"), selection = new BufferSelection();
		var observedChanges = 0, secondObservedChanges = 0;
		var releaseFirst = buffer.subscribe(change -> {
			observedChanges++;
		});
		var releaseSecond = buffer.subscribe(change -> {
			secondObservedChanges++;
		});
		require(buffer.lineCount() == 2 && buffer.line(1) == "beta", "line indexing failed");
		selection.setCursor(buffer, new BufferPosition(0, 5));
		buffer.insert(selection, "!");
		require(observedChanges == 1 && secondObservedChanges == 1, "buffer change subscriptions did not fan out");
		releaseFirst.release();
		require(buffer.text == "alpha!\nbeta" && selection.cursor.equals(new BufferPosition(0, 6)), "insertion failed");
		selection.move(buffer, -5, true);
		require(selection.selectedText(buffer) == "lpha!", "selection failed");
		buffer.insert(selection, "L");
		require(buffer.text == "aL\nbeta" && !selection.hasSelection(), "selection replacement failed");
		buffer.deleteBackward(selection);
		require(buffer.text == "a\nbeta", "backspace failed");
		buffer.deleteForward(selection);
		require(observedChanges == 1 && secondObservedChanges == 4, "released buffer subscription was still invoked");
		require(buffer.text == "abeta", "forward delete failed");
		require(buffer.undo(selection) && buffer.text == "a\nbeta", "undo delete failed");
		require(buffer.undo(selection) && buffer.text == "aL\nbeta", "undo backspace failed");
		require(buffer.redo(selection) && buffer.text == "a\nbeta", "redo failed");
		selection.selectAll(buffer);
		buffer.insert(selection, "replacement");
		require(buffer.text == "replacement" && selection.cursor.equals(new BufferPosition(0, 11)), "select-all replacement failed");
		var vertical = new TextBuffer("abcdef\nxy\n123456"), verticalSelection = new BufferSelection();
		verticalSelection.setCursor(vertical, vertical.positionAt(0, 5));
		verticalSelection.moveVertical(vertical, 1);
		require(verticalSelection.cursor.equals(new BufferPosition(1, 2)), "vertical movement did not clamp to short line");
		verticalSelection.moveVertical(vertical, 1);
		require(verticalSelection.cursor.equals(new BufferPosition(2, 5)), "vertical movement did not preserve preferred column");
		verticalSelection.moveVertical(vertical, -1, true);
		require(verticalSelection.hasSelection() && verticalSelection.cursor.column == 2, "vertical selection failed");
		var multiline = new TextBuffer("one\ntwo\nthree"), multilineSelection = new BufferSelection(), cleanState = multiline.stateId;
		multilineSelection.setCursor(multiline, new BufferPosition(0, 2));
		multiline.insert(multilineSelection, "X\nY");
		require(multiline.lineCount() == 4 && multiline.line(0) == "onX" && multiline.line(1) == "Ye", "line splice insertion failed");
		require(multiline.undo(multilineSelection) && multiline.text == "one\ntwo\nthree" && multiline.stateId == cleanState, "range undo failed");
		require(multiline.redo(multilineSelection) && multiline.text == "onX\nYe\ntwo\nthree", "range redo failed");
		var unicode = new TextBuffer("A😀B"), unicodeSelection = new BufferSelection();
		require(unicode.positionAt(0, 2).column == 1 && unicode.positionFromOffset(2).column == 1,
			"position conversion accepted the middle of a surrogate pair");
		unicodeSelection.setCursor(unicode, new BufferPosition(0, 1));
		unicodeSelection.move(unicode, 1);
		require(unicodeSelection.cursor.column == 3, "cursor split a surrogate pair");
		unicode.deleteBackward(unicodeSelection);
		require(unicode.text == "AB" && unicodeSelection.cursor.column == 1, "backspace split a surrogate pair");
		var combining = new TextBuffer("é"), combiningSelection = new BufferSelection();
		combiningSelection.setCursor(combining, new BufferPosition(0, 2));
		combiningSelection.move(combining, -1);
		require(combiningSelection.cursor.column == 1, "combining-mark scalar boundary policy changed");
		var document = new Document("unused", "clean", syntaxes), documentSelection = new BufferSelection();
		document.insert(documentSelection, " edit");
		require(document.dirty && document.buffer.text == " editclean", "document dirty state failed");
		document.undo(documentSelection);
		require(!document.dirty && document.buffer.text == "clean", "undo did not restore document savepoint");
		var searched = new Document("search.txt", "Alpha alpha alphabet\n😀 alpha", syntaxes), searchedSelection = new BufferSelection(),
			options = new SearchOptions();
		var matches = DocumentSearch.find(searched, "alpha", options);
		require(matches.length == 4 && matches[3].line == 1 && matches[3].column == 3, "case-insensitive Unicode search positions failed");
		options.caseSensitive = true;
		require(DocumentSearch.find(searched, "Alpha", options).length == 1, "case-sensitive search failed");
		options.caseSensitive = false;
		options.wholeWord = true;
		require(DocumentSearch.find(searched, "alpha", options).length == 3, "whole-word search failed");
		require(DocumentSearch.replaceAll(searched, searchedSelection, "alpha", "beta", options) == 3, "replace-all count failed");
		require(searched.buffer.text == "beta beta alphabet\n😀 beta", "replace-all content failed");
		require(searched.buffer.undo(searchedSelection) && searched.buffer.text == "Alpha alpha alphabet\n😀 alpha", "replace-all was not one undo transaction");
		var source = new Document("Main.hx", "class Main {\n/* comment\nstill comment */ var value = 42;\n}", syntaxes);
		source.setPath("Main.txt");
		require(source.syntax.name == "Plain Text", "path change did not reselect syntax");
		source.setPath("Main.hx");
		var firstHighlight = source.highlighter.line(0), cachedHighlight = source.highlighter.line(0), comment = source.highlighter.line(1),
			continued = source.highlighter.line(2), stableTail = source.highlighter.line(3);
		require(firstHighlight == cachedHighlight && hasToken(firstHighlight.tokens, HighlightToken.KEYWORD), "highlight cache or keyword token failed");
		require(comment.stateAfter && hasToken(continued.tokens, HighlightToken.COMMENT), "multiline comment state failed");
		var sourceSelection = new BufferSelection();
		sourceSelection.setCursor(source.buffer, new BufferPosition(1, 0));
		sourceSelection.move(source.buffer, 2, true);
		source.insert(sourceSelection, "");
		var updated = source.highlighter.line(2);
		require(updated != continued && !updated.stateBefore, "edit did not invalidate downstream lexical state");
		require(source.highlighter.line(3) == stableTail, "unchanged converged highlight cache was discarded");
		var arguments = Sys.args();
		if (arguments.length > 0) {
			var saveAsPath = arguments[0] + ".save-as";
			if (FileSystem.exists(saveAsPath)) FileSystem.deleteFile(saveAsPath);
			var manager = new DocumentManager(syntaxes), untitled = manager.createUntitled(), untitledSelection = new BufferSelection();
			untitled.insert(untitledSelection, "new document");
			require(manager.saveAs(untitled, saveAsPath) && untitled.path == FileSystem.fullPath(saveAsPath) && !untitled.dirty
				&& File.getContent(saveAsPath) == "new document", "Save As did not assign identity after successful persistence");
			var another = manager.createUntitled(), anotherSelection = new BufferSelection();
			another.insert(anotherSelection, "collision");
			require(!manager.saveAs(another, saveAsPath) && another.path == null && another.dirty,
				"Save As collision changed an untitled document identity");
			FileSystem.deleteFile(saveAsPath);
			var saved = Document.open(arguments[0], syntaxes), savedSelection = new BufferSelection();
			saved.insert(savedSelection, "!");
			require(saved.save() && !saved.dirty && Document.open(arguments[0], syntaxes).buffer.text == "!saved by Haxeon\n", "atomic document save failed");
			File.saveContent(arguments[0], "external\n");
			require(saved.checkExternal() == ExternalState.Current && saved.buffer.text == "external\n", "clean external edit did not reload");
			saved.insert(savedSelection, "dirty ");
			File.saveContent(arguments[0], "other writer\n");
			require(saved.checkExternal() == ExternalState.Changed && !saved.save() && File.getContent(arguments[0]) == "other writer\n",
				"dirty external conflict overwrote disk");
			require(saved.save(true) && File.getContent(arguments[0]) == saved.buffer.text, "explicit conflict overwrite failed");
			var failing = new Document(arguments[0], File.getContent(arguments[0]), syntaxes, new FailingFileSystem()),
				failingSelection = new BufferSelection();
			failing.insert(failingSelection, "unsaved ");
			require(!failing.save() && failing.dirty && File.getContent(arguments[0]) == saved.buffer.text, "failed save changed disk or clean state");
			File.saveContent(arguments[0], "﻿first\r\nsecond\r\n");
			var formatted = Document.open(arguments[0], syntaxes), formattedSelection = new BufferSelection();
			var lastLine = formatted.buffer.lineCount() - 1;
			formattedSelection.setCursor(formatted.buffer, formatted.buffer.positionAt(lastLine, formatted.buffer.line(lastLine).length));
			formatted.insert(formattedSelection, "third\n");
			require(formatted.save() && File.getContent(arguments[0]) == "﻿first\r\nsecond\r\nthird\r\n", "BOM/CRLF format was not preserved");
			var invalidWriteFailed = false;
			try sys.io.AtomicFile.write(arguments[0] + "/missing/file.txt", "bad") catch (error:Dynamic) invalidWriteFailed = true;
			require(invalidWriteFailed, "invalid atomic destination was accepted");
			var exclusiveCreateFailed = false;
			try sys.io.AtomicFile.create(arguments[0], "overwrite") catch (error:Dynamic) exclusiveCreateFailed = true;
			require(exclusiveCreateFailed && File.getContent(arguments[0]) == "﻿first\r\nsecond\r\nthird\r\n",
				"exclusive file creation overwrote an existing file");
			var binaryPath = arguments[0] + ".binary";
			if (FileSystem.exists(binaryPath)) FileSystem.deleteFile(binaryPath);
			var binary = Bytes.alloc(3);
			binary.set(0, 65);
			binary.set(1, 0);
			binary.set(2, 66);
			sys.io.AtomicFile.createBytes(binaryPath, binary);
			var loaded = File.getBytes(binaryPath);
			require(loaded.length == 3 && loaded.get(0) == 65 && loaded.get(1) == 0 && loaded.get(2) == 66,
				"atomic byte publication did not preserve embedded NUL data");
			FileSystem.deleteFile(binaryPath);
		}
		Sys.println("PASS: Haxeon text buffer editing, selections, and history");
		return 0;
	}

	static function hasToken(tokens:Array<HighlightToken>, kind:Int):Bool {
		for (token in tokens)
			if (token.kind == kind) return true;
		return false;
	}
}
