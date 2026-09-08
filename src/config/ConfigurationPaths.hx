package config;

class ConfigurationPaths {
	public static function userSettings():String {
		var portable = Sys.getEnv("PRAGTICAL_PORTABLE");
		if (portable != null && portable.length > 0) return portable + "/settings.conf";
		var config = Sys.getEnv("XDG_CONFIG_HOME");
		if (config != null && config.length > 0) return config + "/pragtical-haxeon/settings.conf";
		var home = Sys.getEnv("HOME");
		return home == null ? "" : home + "/.config/pragtical-haxeon/settings.conf";
	}

	public static function session():String {
		var portable = Sys.getEnv("PRAGTICAL_PORTABLE");
		if (portable != null && portable.length > 0) return portable + "/session.conf";
		var state = Sys.getEnv("XDG_STATE_HOME");
		if (state != null && state.length > 0) return state + "/pragtical-haxeon/session.conf";
		var home = Sys.getEnv("HOME");
		return home == null ? "" : home + "/.local/state/pragtical-haxeon/session.conf";
	}

	public static function recovery():String {
		var sessionPath = session(), separator = sessionPath.lastIndexOf("/");
		return separator < 0 ? "recovery.conf" : sessionPath.substring(0, separator + 1) + "recovery.conf";
	}

	public static function projectSettings(root:String):String
		return root + "/.pragtical/settings.conf";
}
