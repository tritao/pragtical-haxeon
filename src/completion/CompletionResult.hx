package completion;

import editor.BufferPosition;

class CompletionResult {
	public final replaceFrom:BufferPosition;
	public final replaceTo:BufferPosition;
	public final items:Array<CompletionItem>;

	public function new(replaceFrom:BufferPosition, replaceTo:BufferPosition, items:Array<CompletionItem>) {
		this.replaceFrom = replaceFrom;
		this.replaceTo = replaceTo;
		this.items = items;
	}
}
