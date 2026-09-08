package workspace;

import editor.Document;

class FileOperationResult {
	public final success:Bool;
	public final detail:String;
	public final destination:Null<String>;
	public final documents:Array<Document>;

	public function new(success:Bool, detail:String = "", ?destination:String, ?documents:Array<Document>) {
		this.success = success;
		this.detail = detail;
		this.destination = destination;
		this.documents = documents == null ? [] : documents;
	}
}
