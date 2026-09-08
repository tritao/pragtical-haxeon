package language;

import editor.BufferSubscription;
import editor.Document;

class LanguageDocumentState {
	public final document:Document;
	public var uri:String;
	public var version:Int;
	public var revision:Int;
	public var subscription:Null<BufferSubscription>;

	public function new(document:Document, uri:String) {
		this.document = document;
		this.uri = uri;
		version = 1;
		revision = document.buffer.stateId;
	}

	public function release():Void {
		if (subscription != null) subscription.release();
		subscription = null;
	}
}
