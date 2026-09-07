package platform;

class Platform {
	public static inline final ABI_VERSION = 1;
	public static inline final EVENT_QUIT = 1;
	public static inline final EVENT_WINDOW_RESIZED = 2;

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
