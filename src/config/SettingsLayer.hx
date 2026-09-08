package config;

class SettingsLayer {
	public final name:String;
	public final path:String;
	public var content:String = "";

	public function new(name:String, path:String) {
		this.name = name;
		this.path = path;
	}
}
