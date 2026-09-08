package search;

class ReplacementBackup {
	public final path:String;
	public final text:String;
	public final expectedCurrent:String;
	public final matchCount:Int;

	public function new(path:String, text:String, expectedCurrent:String, matchCount:Int) {
		this.path = path;
		this.text = text;
		this.expectedCurrent = expectedCurrent;
		this.matchCount = matchCount;
	}
}
