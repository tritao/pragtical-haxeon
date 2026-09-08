package config;

class Settings {
	public static inline final VERSION = 1;
	public var fontPath:String = "data/fonts/JetBrainsMono-Regular.ttf";
	public var fontSize:Int = 15;
	public var sidebarWidth:Int = 220;
	public var tabWidth:Int = 4;
	public var insertSpaces:Bool = true;
	public var excludedNames:Array<String> = [".git", ".hg", ".svn", ".devstack", "build", "out", "node_modules"];
	public var searchCaseSensitive:Bool = false;
	public var searchWholeWord:Bool = false;
	public var searchMaxResults:Int = 10000;
	public var editorBackground:Int = 404232447;
	public var editorForeground:Int = -421075201;
	public var accent:Int = 1334824191;
	public var keybindings:Array<ConfiguredKeyBinding> = [];

	public function new() {}

	public function copy():Settings {
		var result = new Settings();
		result.fontPath = fontPath;
		result.fontSize = fontSize;
		result.sidebarWidth = sidebarWidth;
		result.tabWidth = tabWidth;
		result.insertSpaces = insertSpaces;
		result.excludedNames = copyStrings(excludedNames);
		result.searchCaseSensitive = searchCaseSensitive;
		result.searchWholeWord = searchWholeWord;
		result.searchMaxResults = searchMaxResults;
		result.editorBackground = editorBackground;
		result.editorForeground = editorForeground;
		result.accent = accent;
		result.keybindings = [for (binding in keybindings) binding.copy()];
		return result;
	}

	static function copyStrings(values:Array<String>):Array<String>
		return [for (value in values) value];
}
