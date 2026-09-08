package jobs;

interface JobTask {
	/** Performs one bounded unit. Returns true when no work remains. */
	function step():Bool;
	function cancel():Void;
}
