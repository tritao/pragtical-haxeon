package completion;

import editor.BufferPosition;
import editor.Document;

class CompletionRegistry {
	final contributions:Array<CompletionContribution> = [];

	public function new() {}

	public function add(owner:String, provider:CompletionProvider):Void {
		if (owner.length == 0) throw "completion provider owner cannot be empty";
		contributions.push(new CompletionContribution(owner, provider));
	}

	public function remove(owner:String, provider:CompletionProvider):Bool {
		for (contribution in contributions)
			if (contribution.owner == owner && contribution.provider == provider)
				return contributions.remove(contribution);
		return false;
	}

	public function removeOwner(owner:String):Void {
		var index = contributions.length;
		while (index > 0) {
			index--;
			if (contributions[index].owner == owner) contributions.splice(index, 1);
		}
	}

	public function request(document:Document, position:BufferPosition):CompletionResult {
		var buffer = document.buffer, target = buffer.positionAt(position.line, position.column), from = target;
		while (from.line != 0 || from.column != 0) {
			var previous = buffer.positionOffset(from, -1);
			if (!isWord(buffer.characterCodeAt(previous))) break;
			from = previous;
		}
		var
			prefix = buffer.textRange(from, target), request = new CompletionRequest(document, target, from, prefix),
			items:Array<CompletionItem> = [], seen:Map<String, Bool> = [];
		for (contribution in contributions)
			for (item in contribution.provider.complete(request))
				if (item.insertText.length > 0 && !seen.exists(item.insertText)) {
					seen.set(item.insertText, true);
					items.push(item);
				}
		items.sort(function(left, right) return Reflect.compare(left.label, right.label));
		return new CompletionResult(from, target, items);
	}

	public function count():Int return contributions.length;

	static function isWord(code:Int):Bool
		return code >= 48 && code <= 57 || code >= 65 && code <= 90 || code >= 97 && code <= 122 || code == 95 || code >= 128;
}
