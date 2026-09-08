package jobs;

class JobHandle {
	public final id:Int;
	public final generation:Int;

	public function new(id:Int, generation:Int) {
		this.id = id;
		this.generation = generation;
	}
}
