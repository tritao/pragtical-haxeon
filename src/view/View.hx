package view;

import editor.Document;
import search.SearchMatch;

class View {
	public var title(default, null):String;

	public function new(title:String) {
		this.title = title;
	}

	public function setTitle(title:String):Void
		this.title = title;

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
	public function scrollX():Int return 0;
	public function scrollY():Int return 0;
	public function restoreScroll(x:Int, y:Int):Void {}
	public function activate():Void {}
	public function deactivate():Void {}
	public function cursorLine():Int return 0;
	public function cursorColumn():Int return 0;
	public function restoreCursor(line:Int, column:Int):Void {}
	public function setSearchMatches(matches:Array<SearchMatch>):Void {}
	public function wheel(vertical:Int, horizontal:Int):Void {}
	public function mouseDown(button:Int, x:Int, y:Int):Void {}
	public function mouseMove(x:Int, y:Int):Void {}
	public function mouseUp(button:Int):Void {}
	public function draw():Void {}
}
