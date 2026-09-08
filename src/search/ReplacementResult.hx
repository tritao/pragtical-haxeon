package search;

class ReplacementResult {
	public final outcomes:Array<ReplacementOutcome>;
	public var appliedFiles(default, null):Int = 0;
	public var appliedMatches(default, null):Int = 0;
	public var conflicts(default, null):Int = 0;
	public var failures(default, null):Int = 0;

	public function new(outcomes:Array<ReplacementOutcome>) {
		this.outcomes = outcomes;
		for (outcome in outcomes)
			switch outcome.state {
				case ReplacementOutcome.APPLIED:
					appliedFiles++;
					appliedMatches += outcome.matchCount;
				case ReplacementOutcome.CONFLICT: conflicts++;
				default: failures++;
			}
	}
}
