package commandview;

import platform.Platform;
import renderer.Renderer;

class CommandView {
	public var active(default, null):Bool = false;
	public var query(default, null):String = "";
	public var selected(default, null):Int = 0;
	public final results:Array<CommandViewEntry> = [];
	var provider:Null<CommandViewProvider>;

	public function new() {}

	public function open(provider:CommandViewProvider):Void {
		this.provider = provider;
		query = "";
		selected = 0;
		active = true;
		filter();
		provider.onQuery(query);
	}

	public function close(cancel:Bool = false):Void {
		var current = provider;
		active = false;
		provider = null;
		if (cancel && current != null) current.onCancel();
	}

	public function textInput(value:String):Void {
		query += value;
		changed();
	}

	public function keyPressed(key:Int, modifiers:Int):Bool {
		if (!active) return false;
		if (key == Platform.KEY_ESCAPE) close(true);
		else if (key == Platform.KEY_BACKSPACE) {
			if (query.length > 0) query = query.substring(0, query.length - 1);
			changed();
		} else if (key == Platform.KEY_UP) move(-1);
		else if (key == Platform.KEY_DOWN) move(1);
		else if (key == Platform.KEY_ENTER) accept((modifiers & Platform.MOD_SHIFT) != 0);
		return true;
	}

	function changed():Void {
		filter();
		if (provider != null) provider.onQuery(query);
	}

	function move(delta:Int):Void {
		if (provider != null) provider.onMove(delta);
		if (results.length == 0) return;
		selected += delta;
		if (selected < 0) selected = results.length - 1;
		if (selected >= results.length) selected = 0;
	}

	function accept(backwards:Bool):Void {
		var current = provider;
		if (current == null) return;
		var entry = selected >= 0 && selected < results.length ? results[selected] : null;
		current.onAccept(entry, query, backwards);
	}

	public function draw(renderer:Renderer, windowWidth:Int, windowHeight:Int):Void {
		if (!active || provider == null) return;
		var width = windowWidth - 80;
		if (width > 640) width = 640;
		if (width < 200) width = 200;
		var x = Std.int((windowWidth - width) / 2), y = 48, rowHeight = 26, visible = results.length;
		if (visible > 10) visible = 10;
		var height = 42 + visible * rowHeight;
		renderer.clip(0, 0, windowWidth, windowHeight);
		renderer.rect(0, 0, windowWidth, windowHeight, 0x00000066);
		renderer.rect(x - 2, y - 2, width + 4, height + 4, 0x111111ff);
		renderer.rect(x, y, width, 40, 0x252932ff);
		renderer.text(x + 12, y + 11, provider.prompt + query, 0xffffffff);
		for (index in 0...visible) {
			var rowY = y + 42 + index * rowHeight, entry = results[index];
			if (index == selected) renderer.rect(x, rowY, width, rowHeight, 0x094771ff);
			renderer.text(x + 12, rowY + 5, entry.label, 0xe6e6e6ff);
			if (entry.detail.length > 0) renderer.text(x + Std.int(width * 0.55), rowY + 5, entry.detail, 0x999999ff);
		}
	}

	function filter():Void {
		results.resize(0);
		if (provider == null) return;
		for (entry in provider.entries) {
			var score = fuzzyScore(entry.label, query);
			if (score >= 0) {
				entry.score = score;
				results.push(entry);
			}
		}
		results.sort(function(left, right) return left.score == right.score ? Reflect.compare(left.label, right.label) : right.score - left.score);
		selected = 0;
	}

	static function fuzzyScore(value:String, query:String):Int {
		if (query.length == 0) return 0;
		var text = value.toLowerCase(), needle = query.toLowerCase(), position = 0, score = 0, previous = -2;
		for (index in 0...needle.length) {
			var found = text.indexOf(needle.charAt(index), position);
			if (found < 0) return -1;
			score += found == previous + 1 ? 10 : 1;
			if (found == 0 || text.charAt(found - 1) == "/" || text.charAt(found - 1) == ":") score += 5;
			previous = found;
			position = found + 1;
		}
		return score;
	}
}
