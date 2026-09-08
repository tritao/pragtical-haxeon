package completion;

class CompletionItem {
	public final label:String;
	public final detail:String;
	public final insertText:String;

	public function new(label:String, detail:String = "", ?insertText:String) {
		this.label = label;
		this.detail = detail;
		this.insertText = insertText == null ? label : insertText;
	}
}
