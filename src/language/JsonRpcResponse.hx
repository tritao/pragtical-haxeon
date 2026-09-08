package language;

class JsonRpcResponse {
	public final result:Dynamic;
	public final error:Null<String>;

	public function new(result:Dynamic, ?error:String) {
		this.result = result;
		this.error = error;
	}
}
