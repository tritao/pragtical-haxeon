package view;

import editor.Document;
import editor.EditorView;
import renderer.Renderer;

class DocumentView extends View {
	public final document:Document;
	public final editor:EditorView;

	public function new(document:Document, renderer:Renderer, width:Int, height:Int) {
		super(document.path);
		this.document = document;
		editor = new EditorView(document, renderer, width, height);
	}

	override public function isDirty():Bool
		return document.dirty;

	override public function getDocument():Null<Document>
		return document;

	override public function moveVertical(delta:Int, extend:Bool):Void
		editor.moveVertical(delta, extend);

	override public function resize(width:Int, height:Int):Void
		editor.resize(width, height);

	override public function textInput(text:String):Void {
		document.insert(text);
		editor.cursorChanged();
	}

	override public function cursorChanged():Void
		editor.cursorChanged();

	override public function wheel(vertical:Int, horizontal:Int):Void
		editor.wheel(vertical, horizontal);

	override public function mouseDown(button:Int, x:Int, y:Int):Void
		editor.mouseDown(button, x, y);

	override public function mouseMove(x:Int, y:Int):Void
		editor.mouseMove(x, y);

	override public function mouseUp(button:Int):Void
		editor.mouseUp(button);

	override public function draw():Void
		editor.draw(document.path);
}
