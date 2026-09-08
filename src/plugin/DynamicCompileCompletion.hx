package plugin;

class DynamicCompileCompletion {
	public final generation:Int;
	public final build:Null<compiler.CompileResult>;
	public final error:Null<String>;

	public function new(generation:Int, build:Null<compiler.CompileResult>, error:Null<String>) {
		this.generation = generation;
		this.build = build;
		this.error = error;
	}
}
