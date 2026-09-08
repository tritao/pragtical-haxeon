package view;

import renderer.Renderer;
import style.Theme;
import search.SearchMatch;

class SearchSidebar {
	public static inline final HEADER_HEIGHT = Sidebar.HEADER_HEIGHT;
	public static inline final ROW_HEIGHT = 38;
	public var width:Int;
	public final results:Array<SearchMatch> = [];
	public var selected(default, null):Int = 0;
	public var query(default, null):String = "";

	public function new(width:Int = Sidebar.WIDTH) {
		this.width = width;
	}

	public function setResults(query:String, values:Array<SearchMatch>):Void {
		this.query = query;
		results.resize(0);
		for (value in values) results.push(value);
		selected = 0;
	}

	public function selectBy(delta:Int):Bool {
		if (results.length == 0) return false;
		selected += delta;
		if (selected < 0) selected = 0;
		if (selected >= results.length) selected = results.length - 1;
		return true;
	}

	public function active():Null<SearchMatch>
		return selected >= 0 && selected < results.length ? results[selected] : null;

	public function mouseDown(x:Int, y:Int):Null<SearchMatch> {
		if (x < 0 || x >= width || y < HEADER_HEIGHT) return null;
		selected = Std.int((y - HEADER_HEIGHT) / ROW_HEIGHT);
		return active();
	}

	public function draw(renderer:Renderer, theme:Theme, height:Int):Void {
		renderer.clip(0, 0, width, height);
		renderer.rect(0, 0, width, height, theme.surface);
		renderer.text(16, 13, 'SEARCH (${results.length})', theme.foregroundMuted);
		var maxRows = Std.int((height - HEADER_HEIGHT) / ROW_HEIGHT);
		if (maxRows > results.length) maxRows = results.length;
		for (index in 0...maxRows) {
			var match = results[index], y = HEADER_HEIGHT + index * ROW_HEIGHT;
			if (index == selected) renderer.rect(0, y, width, ROW_HEIGHT, theme.surfaceActive);
			renderer.text(10, y + 3, shortPath(match.path) + ':' + (match.line + 1), theme.foregroundMuted);
			renderer.text(18, y + 20, match.preview, theme.foregroundSubtle);
		}
	}

	static function shortPath(path:String):String {
		var slash = path.lastIndexOf("/");
		return slash < 0 ? path : path.substring(slash + 1);
	}
}
