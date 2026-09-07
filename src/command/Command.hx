package command;

class Command {
	public final name:String;
	public final predicate:CommandContext->Bool;
	public final perform:CommandContext->Void;

	public function new(name:String, perform:CommandContext->Void, ?predicate:CommandContext->Bool) {
		this.name = name;
		this.perform = perform;
		this.predicate = predicate == null ? function(context:CommandContext) { return true; } : predicate;
	}
}
