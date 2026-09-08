package platform;

class Platform {
	public static inline final ABI_VERSION = 5;
	public static inline final EVENT_QUIT = 1;
	public static inline final EVENT_WINDOW_RESIZED = 2;
	public static inline final EVENT_KEY_DOWN = 3;
	public static inline final EVENT_TEXT_INPUT = 5;
	public static inline final EVENT_MOUSE_MOVED = 6;
	public static inline final EVENT_MOUSE_BUTTON_DOWN = 7;
	public static inline final EVENT_MOUSE_BUTTON_UP = 8;
	public static inline final EVENT_MOUSE_WHEEL = 9;
	public static inline final MOUSE_LEFT = 1;
	public static inline final KEY_BACKSPACE = 1;
	public static inline final KEY_TAB = 2;
	public static inline final KEY_ENTER = 3;
	public static inline final KEY_ESCAPE = 4;
	public static inline final KEY_DELETE = 5;
	public static inline final KEY_LEFT = 6;
	public static inline final KEY_RIGHT = 7;
	public static inline final KEY_UP = 8;
	public static inline final KEY_DOWN = 9;
	public static inline final KEY_HOME = 10;
	public static inline final KEY_END = 11;
	public static inline final KEY_A = 12;
	public static inline final KEY_S = 13;
	public static inline final KEY_Y = 14;
	public static inline final KEY_Z = 15;
	public static inline final KEY_W = 16;
	public static inline final KEY_P = 17;
	public static inline final KEY_F = 18;
	public static inline final KEY_H = 19;
	public static inline final KEY_C = 20;
	public static inline final KEY_V = 21;
	public static inline final KEY_X = 22;
	public static inline final MOD_SHIFT = 1;
	public static inline final MOD_CTRL = 2;

	public static function require(condition:Bool, operation:String):Void {
		if (!condition)
			throw operation + ": " + Native.last_error();
	}

	public static function startHeadless():Void {
		if (Native.abi_version() != ABI_VERSION)
			throw "platform ABI version mismatch";
		require(Native.init(true), "initialize platform");
	}
}
