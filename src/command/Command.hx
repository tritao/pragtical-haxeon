package command;

class Command {
	public final name:String;
	public final predicate:Void->Bool;
	public final perform:Void->Void;

	public function new(name:String, perform:Void->Void, ?predicate:Void->Bool) {
		this.name = name;
		this.perform = perform;
		this.predicate = predicate == null ? function() { return true; } : predicate;
	}
}
