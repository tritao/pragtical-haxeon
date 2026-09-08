package completion;

class DocumentWordCompletionProvider implements CompletionProvider {
	public function new() {}

	public function complete(request:CompletionRequest):Array<CompletionItem> {
		var text = request.document.buffer.text, words:Map<String, Bool> = [], result:Array<CompletionItem> = [], start = -1;
		for (index in 0...text.length + 1) {
			var code = index < text.length ? text.charCodeAt(index) : -1;
			if (isWord(code)) {
				if (start < 0) start = index;
			} else if (start >= 0) {
				var word = text.substring(start, index);
				if (word != request.prefix && word.length > 1 && StringTools.startsWith(word, request.prefix) && !words.exists(word)) {
					words.set(word, true);
					result.push(new CompletionItem(word, "Document word"));
				}
				start = -1;
			}
		}
		return result;
	}

	static function isWord(code:Int):Bool
		return code >= 48 && code <= 57 || code >= 65 && code <= 90 || code >= 97 && code <= 122 || code == 95 || code >= 128;
}
