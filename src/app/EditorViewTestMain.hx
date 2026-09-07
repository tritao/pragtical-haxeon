package app;

import editor.Document;
import editor.EditorView;
import platform.Native;
import platform.Platform;
import renderer.Renderer;
import syntax.BuiltinSyntax;
import syntax.SyntaxRegistry;
import style.Theme;

class EditorViewTestMain {
	static function require(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function main():Int {
		Platform.startHeadless();
		var syntaxes = new SyntaxRegistry();
		BuiltinSyntax.install(syntaxes);
		var window = Native.window_create("view-test", 640, 160), renderer = new Renderer(window, "ignored-headlessly.ttf", 15),
			document = new Document("unused", "abcdef\nxy\n123456\nline four\nline five\nline six\nline seven\nline eight\nline nine\nline ten\nline eleven\nline twelve", syntaxes),
			view = new EditorView(document, renderer, new Theme(), 640, 160);
		document.buffer.setCursor(document.buffer.positionAt(0, 5));
		view.moveVertical(1, false);
		view.moveVertical(1, false);
		require(document.buffer.cursor.line == 2 && document.buffer.cursor.column == 5, "view lost preferred cursor column");
		view.wheel(-100, 0);
		require(view.scrollY > 0, "mouse wheel did not scroll document");
		view.mouseDown(Platform.MOUSE_LEFT, EditorView.GUTTER_WIDTH + 2,
			EditorView.HEADER_HEIGHT + EditorView.PADDING + 2);
		view.mouseMove(EditorView.GUTTER_WIDTH + 40,
			EditorView.HEADER_HEIGHT + EditorView.PADDING + renderer.lineHeight + 2);
		view.mouseUp(Platform.MOUSE_LEFT);
		require(document.buffer.hasSelection(), "mouse drag did not select text");
		renderer.begin();
		view.draw("unused");
		renderer.present();
		renderer.destroy();
		Platform.require(Native.window_destroy(window), "destroy view test window");
		Native.shutdown();
		Sys.println("PASS: editor viewport navigation, scrolling, clipping, and mouse selection");
		return 0;
	}
}
