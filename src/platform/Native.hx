package platform;

@:hlNative("pragtical_hx")
extern class Native {
	static function abi_version():Int;
	static function init(headless:Bool):Bool;
	static function shutdown():Void;
	static function last_error():String;
	static function window_create(title:String, width:Int, height:Int):Int;
	static function window_destroy(window:Int):Bool;
	static function window_valid(window:Int):Bool;
	static function event_poll():Bool;
	static function event_kind():Int;
	static function event_window():Int;
	static function event_a():Int;
	static function event_b():Int;
	static function event_text():String;
	static function event_push_test(kind:Int, window:Int, a:Int, b:Int):Bool;
	static function frame_begin(window:Int):Bool;
	static function draw_rect(window:Int, x:Int, y:Int, width:Int, height:Int, rgba:Int):Bool;
	static function draw_text(window:Int, x:Int, y:Int, text:String, rgba:Int):Bool;
	static function frame_present(window:Int):Bool;
	static function frame_count(window:Int):Int;
}
