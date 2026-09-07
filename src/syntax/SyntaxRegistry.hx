package syntax;

class SyntaxRegistry {
	final definitions:Array<SyntaxDefinition> = [];
	final owners:Map<String, Array<SyntaxDefinition>> = [];
	public final plainText = new SyntaxDefinition("Plain Text", [], false);

	public function new() {}

	public function add(definition:SyntaxDefinition, owner:String = "core"):Void {
		for (existing in definitions)
			if (existing.name == definition.name) throw 'syntax "${definition.name}" is already registered';
		definitions.push(definition);
		var owned = owners.get(owner);
		if (owned == null) {
			owned = [];
			owners.set(owner, owned);
		}
		owned.push(definition);
	}

	public function removeOwner(owner:String):Void {
		var owned = owners.get(owner);
		if (owned == null) return;
		for (definition in owned) definitions.remove(definition);
		owners.remove(owner);
	}

	public function find(path:String, header:String = ""):SyntaxDefinition {
		var lower = path.toLowerCase(), index = definitions.length;
		while (index > 0) {
			index--;
			for (extension in definitions[index].extensions)
				if (StringTools.endsWith(lower, extension.toLowerCase())) return definitions[index];
		}
		index = definitions.length;
		while (index > 0) {
			index--;
			for (prefix in definitions[index].headers)
				if (StringTools.startsWith(header, prefix)) return definitions[index];
		}
		return plainText;
	}
}
