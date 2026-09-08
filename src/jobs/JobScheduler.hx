package jobs;

class JobScheduler {
	var nextId:Int = 1;
	var cursor:Int = 0;
	final generations:Map<Int, Int> = [];
	final jobs:Array<ScheduledJob> = [];

	public function new() {}

	public function schedule(task:JobTask):JobHandle {
		var id = nextId++, handle = new JobHandle(id, 1);
		generations.set(id, 1);
		jobs.push(new ScheduledJob(handle, task));
		return handle;
	}

	public function replace(handle:JobHandle, task:JobTask):JobHandle {
		cancel(handle);
		var generation = currentGeneration(handle.id) + 1, replacement = new JobHandle(handle.id, generation);
		generations.set(handle.id, generation);
		jobs.push(new ScheduledJob(replacement, task));
		return replacement;
	}

	public function cancel(handle:JobHandle):Bool {
		for (index in 0...jobs.length) {
			var job = jobs[index];
			if (job.handle.id == handle.id && job.handle.generation == handle.generation) {
				job.task.cancel();
				jobs.splice(index, 1);
				if (cursor > index) cursor--;
				if (cursor >= jobs.length) cursor = 0;
				return true;
			}
		}
		return false;
	}

	public function update(maxSteps:Int):Int {
		if (maxSteps < 0) throw "job step budget must be non-negative";
		var performed = 0;
		while (performed < maxSteps && jobs.length > 0) {
			if (cursor >= jobs.length) cursor = 0;
			var job = jobs[cursor], complete = job.task.step();
			performed++;
			if (complete) jobs.splice(cursor, 1); else cursor++;
		}
		return performed;
	}

	public function isCurrent(handle:JobHandle):Bool
		return currentGeneration(handle.id) == handle.generation;

	public function activeCount():Int
		return jobs.length;

	function currentGeneration(id:Int):Int {
		var value = generations.get(id);
		return value == null ? 0 : value;
	}
}
