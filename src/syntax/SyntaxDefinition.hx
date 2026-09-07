package syntax;

class SyntaxDefinition {
	public final name:String;
	public final keywords:Map<String, Int>;
	public final highlighting:Bool;

	public function new(name:String, highlighting:Bool, ?keywords:Map<String, Int>) {
		this.name = name;
		this.highlighting = highlighting;
		this.keywords = keywords == null ? [] : keywords;
	}

	public static function forPath(path:String):SyntaxDefinition {
		if (!StringTools.endsWith(path.toLowerCase(), ".hx")) return new SyntaxDefinition("Plain Text", false);
		var symbols:Map<String, Int> = [];
		for (word in ["abstract", "break", "case", "catch", "class", "continue", "default", "do", "dynamic", "else", "enum", "extends",
			"extern", "final", "for", "function", "if", "implements", "import", "in", "inline", "interface", "macro", "new", "override",
			"package", "private", "public", "return", "static", "switch", "throw", "try", "typedef", "untyped", "using", "var", "while"])
			symbols.set(word, HighlightToken.KEYWORD);
		for (word in ["Any", "Bool", "Dynamic", "Float", "Int", "Null", "String", "UInt", "Void"])
			symbols.set(word, HighlightToken.TYPE);
		for (word in ["false", "null", "this", "true"])
			symbols.set(word, HighlightToken.LITERAL);
		return new SyntaxDefinition("Haxe", true, symbols);
	}
}
