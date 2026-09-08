package search;

class ReplacementOutcome {
	public static inline final APPLIED = "applied";
	public static inline final CONFLICT = "conflict";
	public static inline final FAILED = "failed";
	public final path:String;
	public final state:String;
	public final matchCount:Int;
	public final detail:String;

	public function new(path:String, state:String, matchCount:Int, detail:String = "") {
		this.path = path;
		this.state = state;
		this.matchCount = matchCount;
		this.detail = detail;
	}
}
