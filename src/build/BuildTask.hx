package build;

class BuildTask {
	public final name:String;
	public var executable:String = "";
	public var cwd:String = "";
	public final arguments:Array<String> = [];
	public final environment:Map<String, String> = [];

	public function new(name:String) {
		this.name = name;
	}
}
