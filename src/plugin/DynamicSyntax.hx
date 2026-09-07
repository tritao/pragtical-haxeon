package plugin;

import syntax.BuiltinSyntax;
import syntax.SyntaxDefinition;

class DynamicSyntax {
	public final name:String;
	public final extensions:Array<String>;
	public final keywords:Array<String>;
	public final types:Array<String>;
	public final literals:Array<String>;

	public function new(name:String, extensions:Array<String>, keywords:Array<String>, types:Array<String>, literals:Array<String>) {
		this.name = name;
		this.extensions = extensions;
		this.keywords = keywords;
		this.types = types;
		this.literals = literals;
	}

	public function definition():SyntaxDefinition
		return BuiltinSyntax.definition(name, extensions, keywords, types, literals);
}
