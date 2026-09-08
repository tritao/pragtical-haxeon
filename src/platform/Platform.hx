package platform;

class Platform extends PlatformAbi {

	public static function require(condition:Bool, operation:String):Void {
		if (!condition)
			throw operation + ": " + Native.last_error();
	}

	public static function pollEvent():Null<PlatformEvent> {
		return PlatformEventDecoder.poll();
	}

	public static function startHeadless():Void {
		if (Native.abi_version() != ABI_VERSION)
			throw "platform ABI version mismatch";
		require(Native.init(true), "initialize platform");
	}
}
