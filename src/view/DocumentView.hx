package view;

import editor.Document;
import editor.EditorView;
import renderer.Renderer;
import style.Theme;
import search.SearchMatch;
import editor.BufferPosition;

class DocumentView extends View {
	public final document:Document;
	public final editor:EditorView;
	var viewCursor:BufferPosition;
	var viewAnchor:BufferPosition;

	public function new(document:Document, renderer:Renderer, theme:Theme, width:Int, height:Int) {
		super(document.title);
		this.document = document;
		editor = new EditorView(document, renderer, theme, width, height);
		viewCursor = document.buffer.cursor;
		viewAnchor = document.buffer.anchor;
	}

	override public function isDirty():Bool
		return document.dirty;

	override public function getDocument():Null<Document>
		return document;

	override public function moveVertical(delta:Int, extend:Bool):Void {
		editor.moveVertical(delta, extend);
		captureSelection();
	}

	override public function resize(width:Int, height:Int):Void
		editor.resize(width, height);

	override public function setBounds(x:Int, y:Int, width:Int, height:Int):Void
		editor.setBounds(x, y, width, height);

	override public function textInput(text:String):Void {
		document.insert(text);
		editor.cursorChanged();
		captureSelection();
	}

	override public function cursorChanged():Void {
		editor.cursorChanged();
		captureSelection();
	}

	override public function scrollX():Int return editor.scrollX;
	override public function scrollY():Int return editor.scrollY;
	override public function restoreScroll(x:Int, y:Int):Void editor.restoreScroll(x, y);
	override public function activate():Void document.buffer.restoreSelection(viewCursor, viewAnchor);
	override public function deactivate():Void captureSelection();
	override public function cursorLine():Int return viewCursor.line;
	override public function cursorColumn():Int return viewCursor.column;
	override public function restoreCursor(line:Int, column:Int):Void {
		viewCursor = document.buffer.positionAt(line, column);
		viewAnchor = viewCursor;
		activate();
	}

	override public function setSearchMatches(matches:Array<SearchMatch>):Void
		editor.setSearchMatches(matches);
	override public function searchMatchCount():Int return editor.searchMatches.length;

	override public function wheel(vertical:Int, horizontal:Int):Void
		editor.wheel(vertical, horizontal);

	override public function mouseDown(button:Int, x:Int, y:Int):Void {
		editor.mouseDown(button, x, y);
		captureSelection();
	}

	override public function mouseMove(x:Int, y:Int):Void {
		editor.mouseMove(x, y);
		captureSelection();
	}

	override public function mouseUp(button:Int):Void
		editor.mouseUp(button);

	override public function draw():Void {
		var cursor = document.buffer.cursor, anchor = document.buffer.anchor;
		document.buffer.restoreSelection(viewCursor, viewAnchor);
		editor.draw(document.title);
		document.buffer.restoreSelection(cursor, anchor);
	}

	function captureSelection():Void {
		viewCursor = document.buffer.cursor;
		viewAnchor = document.buffer.anchor;
	}
}
