package view;

import config.Settings;
import renderer.Renderer;
import style.Theme;

class StatusView {
	public static inline final HEIGHT = 24;
	final renderer:Renderer;
	final theme:Theme;
	var settings:Settings;

	public function new(renderer:Renderer, theme:Theme, settings:Settings) {
		this.renderer = renderer;
		this.theme = theme;
		this.settings = settings;
	}

	public function applySettings(settings:Settings):Void
		this.settings = settings;

	public function text(view:Null<View>):String {
		if (view == null) return "No editor";
		var document = view.getDocument();
		if (document == null) return view.title;
		var path = document.path == null ? document.title : document.requirePath(), selection = view.getSelection(), selectionText = "";
		if (selection != null) {
			var count = selection.rangeCount(), length = 0;
			for (range in selection.documentRanges())
				length += document.buffer.offsetOf(range.end()) - document.buffer.offsetOf(range.start());
			selectionText = count > 1 ? '  $count selections' : length > 0 ? '  Selected $length' : "";
		}
		var indentation = settings.insertSpaces ? 'Spaces: ${settings.tabWidth}' : 'Tab Size: ${settings.tabWidth}';
		return (document.dirty ? "* " : "") + path + '  Ln ${view.cursorLine() + 1}, Col ${view.cursorColumn() + 1}'
			+ selectionText + '  $indentation  ${document.encodingLabel()}  ${document.newlineLabel()}';
	}

	public function draw(view:Null<View>, width:Int, height:Int):Void {
		var y = height - HEIGHT;
		renderer.clip(0, y, width, HEIGHT);
		renderer.rect(0, y, width, HEIGHT, theme.accent);
		renderer.text(8, y + 4, text(view), theme.editorForeground);
	}
}
