package language;

class JsonRpcPending {
	public final id:Int;
	public final deadline:Float;
	public final complete:JsonRpcResponse->Void;

	public function new(id:Int, deadline:Float, complete:JsonRpcResponse->Void) {
		this.id = id;
		this.deadline = deadline;
		this.complete = complete;
	}
}
