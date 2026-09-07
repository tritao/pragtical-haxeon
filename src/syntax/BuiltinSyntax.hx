package syntax;

class BuiltinSyntax {
	public static function install(registry:SyntaxRegistry):Void {
		registry.add(definition("Haxe", [".hx"],
			["abstract", "break", "case", "catch", "class", "continue", "default", "do", "dynamic", "else", "enum", "extends", "extern",
				"final", "for", "function", "if", "implements", "import", "in", "inline", "interface", "macro", "new", "override", "package",
				"private", "public", "return", "static", "switch", "throw", "try", "typedef", "untyped", "using", "var", "while"],
			["Any", "Bool", "Dynamic", "Float", "Int", "Null", "String", "UInt", "Void"], ["false", "null", "this", "true"]));
		registry.add(new SyntaxDefinition("JSON", [".json"], true, symbols([], [], ["false", "null", "true"]), [], "", "", ""));
		registry.add(new SyntaxDefinition("Markdown", [".md", ".markdown"], false));
		registry.add(new SyntaxDefinition("Lua", [".lua"], true, symbols(
			["and", "break", "do", "else", "elseif", "end", "for", "function", "goto", "if", "in", "local", "not", "or", "repeat", "return",
				"then", "until", "while"], [], ["false", "nil", "true"]), ["#!/usr/bin/env lua", "#!/usr/bin/lua"], "--", "--[[", "]]"));
	}

	public static function definition(name:String, extensions:Array<String>, keywords:Array<String>, types:Array<String>, literals:Array<String>):SyntaxDefinition {
		return new SyntaxDefinition(name, extensions, true, symbols(keywords, types, literals));
	}

	static function symbols(keywords:Array<String>, types:Array<String>, literals:Array<String>):Map<String, Int> {
		var symbols:Map<String, Int> = [];
		for (word in keywords) symbols.set(word, HighlightToken.KEYWORD);
		for (word in types) symbols.set(word, HighlightToken.TYPE);
		for (word in literals) symbols.set(word, HighlightToken.LITERAL);
		return symbols;
	}
}
