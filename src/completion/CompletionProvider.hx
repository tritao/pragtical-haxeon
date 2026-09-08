package completion;

interface CompletionProvider {
	function complete(request:CompletionRequest):Array<CompletionItem>;
}
