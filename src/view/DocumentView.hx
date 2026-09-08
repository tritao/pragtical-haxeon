package view;

import editor.Document;
import editor.EditorView;
import renderer.Renderer;
import style.Theme;
import search.SearchMatch;
import editor.BufferPosition;
import editor.BufferChange;
import editor.BufferSubscription;

class DocumentView extends View {
	public final document:Document;
	public final editor:EditorView;
	final bufferSubscription:BufferSubscription;

	public function new(document:Document, renderer:Renderer, theme:Theme, width:Int, height:Int) {
		super(document.title);
		this.document = document;
		editor = new EditorView(document, renderer, theme, width, height);
		bufferSubscription = document.buffer.subscribe(bufferChanged);
	}

	override public function isDirty():Bool
		return document.dirty;

	override public function getDocument():Null<Document>
		return document;
	override public function getSelection():Null<editor.BufferSelection>
		return editor.selection;

	override public function moveVertical(delta:Int, extend:Bool):Void {
		editor.moveVertical(delta, extend);
	}

	override public function moveHorizontal(delta:Int, extend:Bool):Void
		editor.selection.move(document.buffer, delta, extend);
	override public function moveHome(extend:Bool):Void editor.selection.moveHome(document.buffer, extend);
	override public function moveEnd(extend:Bool):Void editor.selection.moveEnd(document.buffer, extend);
	override public function selectAll():Void editor.selection.selectAll(document.buffer);
	override public function undo():Void document.buffer.undo(editor.selection);
	override public function redo():Void document.buffer.redo(editor.selection);
	override public function backspace():Void document.buffer.deleteBackward(editor.selection);
	override public function deleteForward():Void document.buffer.deleteForward(editor.selection);
	override public function selectRange(from:BufferPosition, to:BufferPosition):Bool {
		editor.selection.restore(document.buffer, to, from);
		return true;
	}
	override public function replaceRange(from:BufferPosition, to:BufferPosition, text:String):Bool
		return document.buffer.replaceRange(editor.selection, from, to, text);
	override public function replaceAllText(text:String):Bool
		return document.buffer.replaceAllText(text, editor.selection);

	override public function resize(width:Int, height:Int):Void
		editor.resize(width, height);

	override public function setBounds(x:Int, y:Int, width:Int, height:Int):Void
		editor.setBounds(x, y, width, height);

	override public function textInput(text:String):Void {
		document.buffer.insert(editor.selection, text, text.indexOf("\n") < 0);
		editor.cursorChanged();
	}

	override public function cursorChanged():Void {
		editor.cursorChanged();
	}

	override public function scrollX():Int return editor.scrollX;
	override public function scrollY():Int return editor.scrollY;
	override public function restoreScroll(x:Int, y:Int):Void editor.restoreScroll(x, y);
	override public function cursorLine():Int return editor.selection.cursor.line;
	override public function cursorColumn():Int return editor.selection.cursor.column;
	override public function hasSelection():Bool return editor.selection.hasSelection();
	override public function restoreCursor(line:Int, column:Int):Void {
		editor.selection.setCursor(document.buffer, new BufferPosition(line, column));
	}

	override public function setSearchMatches(matches:Array<SearchMatch>):Void
		editor.setSearchMatches(matches);
	override public function searchMatchCount():Int return editor.searchMatches.length;

	override public function wheel(vertical:Int, horizontal:Int):Void
		editor.wheel(vertical, horizontal);

	override public function mouseDown(button:Int, x:Int, y:Int):Void {
		editor.mouseDown(button, x, y);
	}

	override public function mouseMove(x:Int, y:Int):Void {
		editor.mouseMove(x, y);
	}

	override public function mouseUp(button:Int):Void
		editor.mouseUp(button);
	override public function dispose():Void bufferSubscription.release();

	override public function draw():Void editor.draw(document.title);

	function bufferChanged(change:BufferChange):Void {
		editor.selection.transform(document.buffer, change);
	}
}
