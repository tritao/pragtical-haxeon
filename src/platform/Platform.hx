package platform;

class Platform {
	public static inline final ABI_VERSION = 2;
	public static inline final EVENT_QUIT = 1;
	public static inline final EVENT_WINDOW_RESIZED = 2;
	public static inline final EVENT_KEY_DOWN = 3;
	public static inline final EVENT_TEXT_INPUT = 5;
	public static inline final KEY_BACKSPACE = 1;
	public static inline final KEY_TAB = 2;
	public static inline final KEY_ENTER = 3;
	public static inline final KEY_ESCAPE = 4;
	public static inline final KEY_DELETE = 5;
	public static inline final KEY_LEFT = 6;
	public static inline final KEY_RIGHT = 7;
	public static inline final KEY_HOME = 8;
	public static inline final KEY_END = 9;
	public static inline final KEY_A = 10;
	public static inline final KEY_S = 11;
	public static inline final KEY_Y = 12;
	public static inline final KEY_Z = 13;
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
