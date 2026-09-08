package app;

import editor.Document;
import editor.EditorView;
import platform.Native;
import platform.Platform;
import renderer.Renderer;
import syntax.BuiltinSyntax;
import syntax.SyntaxRegistry;
import style.Theme;
import editor.BufferSelection;
import editor.EditorClock;

class FakeEditorClock implements EditorClock {
	public var value:Float = 0.0;
	public function new() {}
	public function now():Float return value;
	public function advance(seconds:Float):Void value += seconds;
}

class EditorViewTestMain {
	static function require(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function main():Int {
		Platform.startHeadless();
		var syntaxes = new SyntaxRegistry();
		BuiltinSyntax.install(syntaxes);
		var clock = new FakeEditorClock();
		var window = Native.window_create("view-test", 640, 160), renderer = new Renderer(window, "ignored-headlessly.ttf", 15),
			document = new Document("unused", "abcdef\nxy\n123456\nline four\nline five\nline six\nline seven\nline eight\nline nine\nline ten\nline eleven\nline twelve", syntaxes),
			view = new EditorView(document, renderer, new Theme(), 640, 160, new BufferSelection(), clock);
		view.mouseDown(Platform.MOUSE_LEFT, EditorView.GUTTER_WIDTH + 20, EditorView.HEADER_HEIGHT + EditorView.PADDING + 2, 2);
		view.mouseUp(Platform.MOUSE_LEFT);
		require(view.selection.selectedText(document.buffer) == "abcdef", "double click did not select a word");
		view.mouseDown(Platform.MOUSE_LEFT, EditorView.GUTTER_WIDTH + 20, EditorView.HEADER_HEIGHT + EditorView.PADDING + 2, 3);
		view.mouseUp(Platform.MOUSE_LEFT);
		require(view.selection.selectedText(document.buffer) == "abcdef\n", "triple click did not select a complete line");
		view.selection.setCursor(document.buffer, document.buffer.positionAt(0, 5));
		view.moveVertical(1, false);
		view.moveVertical(1, false);
		require(view.selection.cursor.line == 2 && view.selection.cursor.column == 5, "view lost preferred cursor column");
		view.movePage(1, false);
		require(view.selection.cursor.line > 2, "page movement did not use the viewport height");
		view.wheel(-100, 0);
		require(view.scrollY > 0, "mouse wheel did not scroll document");
		view.restoreScroll(0, 0);
		view.mouseDown(Platform.MOUSE_LEFT, 639, 100);
		view.mouseMove(639, 150);
		view.mouseUp(Platform.MOUSE_LEFT);
		require(view.scrollY > 0, "vertical scrollbar drag did not scroll the document");
		view.mouseDown(Platform.MOUSE_LEFT, EditorView.GUTTER_WIDTH + 2,
			EditorView.HEADER_HEIGHT + EditorView.PADDING + 2);
		view.mouseMove(EditorView.GUTTER_WIDTH + 40,
			EditorView.HEADER_HEIGHT + EditorView.PADDING + renderer.lineHeight + 2);
		view.mouseUp(Platform.MOUSE_LEFT);
		require(view.selection.hasSelection(), "mouse drag did not select text");
		view.restoreScroll(0, 0);
		var beforeAutoscroll = view.scrollY;
		view.mouseDown(Platform.MOUSE_LEFT, EditorView.GUTTER_WIDTH + 10, EditorView.HEADER_HEIGHT + EditorView.PADDING + 2);
		view.mouseMove(EditorView.GUTTER_WIDTH + 10, 220);
		clock.advance(0.1);
		renderer.begin();
		view.draw("unused");
		renderer.present();
		view.mouseUp(Platform.MOUSE_LEFT);
		require(view.scrollY > beforeAutoscroll && view.selection.cursor.line > 0, "timed drag autoscroll did not advance the viewport");
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
