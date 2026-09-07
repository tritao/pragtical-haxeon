package view;

import editor.Document;

class View {
	public final title:String;

	public function new(title:String) {
		this.title = title;
	}

	public function isDirty():Bool
		return false;

	public function getDocument():Null<Document>
		return null;

	public function moveVertical(delta:Int, extend:Bool):Void {}

	public function resize(width:Int, height:Int):Void {}
	public function textInput(text:String):Void {}
	public function cursorChanged():Void {}
	public function wheel(vertical:Int, horizontal:Int):Void {}
	public function mouseDown(button:Int, x:Int, y:Int):Void {}
	public function mouseMove(x:Int, y:Int):Void {}
	public function mouseUp(button:Int):Void {}
	public function draw():Void {}
}
