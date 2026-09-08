package language;

import editor.BufferPosition;

class LanguageLocation {
	public final path:String;
	public final from:BufferPosition;
	public final to:BufferPosition;

	public function new(path:String, from:BufferPosition, to:BufferPosition) {
		this.path = path;
		this.from = from;
		this.to = to;
	}
}
