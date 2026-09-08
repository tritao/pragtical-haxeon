package jobs;

class ScheduledJob {
	public final handle:JobHandle;
	public final task:JobTask;

	public function new(handle:JobHandle, task:JobTask) {
		this.handle = handle;
		this.task = task;
	}
}
