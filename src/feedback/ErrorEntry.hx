package feedback;

class ErrorEntry {
	public final source:String;
	public final message:String;
	public final createdAt:Float;

	public function new(source:String, message:String, createdAt:Float) {
		this.source = source;
		this.message = message;
		this.createdAt = createdAt;
	}
}
