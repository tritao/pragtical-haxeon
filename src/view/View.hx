package view;

import editor.Document;
import search.SearchMatch;

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
	public function setBounds(x:Int, y:Int, width:Int, height:Int):Void
		resize(width, height);

	public function resize(width:Int, height:Int):Void {}
	public function textInput(text:String):Void {}
	public function cursorChanged():Void {}
	public function setSearchMatches(matches:Array<SearchMatch>):Void {}
	public function wheel(vertical:Int, horizontal:Int):Void {}
	public function mouseDown(button:Int, x:Int, y:Int):Void {}
	public function mouseMove(x:Int, y:Int):Void {}
	public function mouseUp(button:Int):Void {}
	public function draw():Void {}
}
