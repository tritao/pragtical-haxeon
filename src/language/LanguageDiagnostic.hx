package language;

import editor.BufferPosition;

class LanguageDiagnostic {
	public final from:BufferPosition;
	public final to:BufferPosition;
	public final message:String;
	public final severity:Int;

	public function new(from:BufferPosition, to:BufferPosition, message:String, severity:Int) {
		this.from = from;
		this.to = to;
		this.message = message;
		this.severity = severity;
	}
}
