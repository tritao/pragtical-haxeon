package plugin;

import editor.BufferChange;
import editor.Document;

class PluginDocumentEvent {
	public final document:Document;
	public final change:BufferChange;

	public function new(document:Document, change:BufferChange) {
		this.document = document;
		this.change = change;
	}
}
