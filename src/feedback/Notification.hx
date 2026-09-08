package feedback;

class Notification {
	public final message:String;
	public final kind:NotificationKind;
	public final createdAt:Float;

	public function new(message:String, kind:NotificationKind, createdAt:Float) {
		this.message = message;
		this.kind = kind;
		this.createdAt = createdAt;
	}
}
