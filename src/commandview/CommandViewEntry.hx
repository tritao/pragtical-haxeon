package commandview;

class CommandViewEntry {
	public final label:String;
	public final detail:String;
	public final value:String;
	public var score:Int = 0;

	public function new(label:String, detail:String, value:String) {
		this.label = label;
		this.detail = detail;
		this.value = value;
	}
}
