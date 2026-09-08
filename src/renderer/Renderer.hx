package renderer;

import platform.Native;
import platform.Platform;

class Renderer {
	public final window:Int;
	public var font(default, null):Int;
	public var lineHeight(default, null):Int;
	public var fontPath(default, null):String;
	public var fontSize(default, null):Int;
	public var fontFallbackPaths(default, null):Array<String>;

	public function new(window:Int, fontPath:String, fontSize:Int, ?fallbackPaths:Array<String>) {
		this.window = window;
		this.fontPath = fontPath;
		this.fontSize = fontSize;
		this.fontFallbackPaths = fallbackPaths == null ? [] : fallbackPaths.copy();
		font = Native.font_create(window, fontPath, fontSize);
		Platform.require(font != 0, "load editor font");
		addFallbacks(font, this.fontFallbackPaths);
		lineHeight = Native.font_height(font);
	}

	public function reloadFont(fontPath:String, fontSize:Int, ?fallbackPaths:Array<String>):Bool {
		var nextFallbacks = fallbackPaths == null ? [] : fallbackPaths;
		if (this.fontPath == fontPath && this.fontSize == fontSize && this.fontFallbackPaths.join("\n") == nextFallbacks.join("\n")) return true;
		var replacement = Native.font_create(window, fontPath, fontSize);
		if (replacement == 0) return false;
		addFallbacks(replacement, fallbackPaths);
		var previous = font;
		font = replacement;
		lineHeight = Native.font_height(font);
		this.fontPath = fontPath;
		this.fontSize = fontSize;
		this.fontFallbackPaths = nextFallbacks.copy();
		Platform.require(Native.font_destroy(previous), "destroy replaced font");
		return true;
	}

	function addFallbacks(target:Int, paths:Null<Array<String>>):Void {
		if (paths == null) return;
		for (path in paths) Native.font_add_fallback(target, path);
	}

	public function begin():Void
		Platform.require(Native.frame_begin(window), "begin frame");

	public function rect(x:Int, y:Int, width:Int, height:Int, color:Int):Void
		Platform.require(Native.draw_rect(window, x, y, width, height, color), "draw rectangle");

	public function clip(x:Int, y:Int, width:Int, height:Int):Void
		Platform.require(Native.set_clip_rect(window, x, y, width, height), "set clip rectangle");

	public function text(x:Int, y:Int, value:String, color:Int):Void
		Platform.require(Native.draw_text(window, font, x, y, value, color), "draw text");

	public function textWidth(value:String):Int
		return Native.font_text_width(font, value);

	public function present():Void
		Platform.require(Native.frame_present(window), "present frame");

	public function destroy():Void
		Platform.require(Native.font_destroy(font), "destroy editor font");
}
