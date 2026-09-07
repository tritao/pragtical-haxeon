package view;

import core.DocumentManager;
import core.FocusManager;
import editor.Document;
import editor.EditorView;
import renderer.Renderer;

class RootView {
	public static inline final TAB_WIDTH = 180;
	public final node:LayoutNode;
	public final tabs:TabGroup;
	public final renderer:Renderer;
	var width:Int;
	var height:Int;

	public function new(renderer:Renderer, focus:FocusManager, documents:DocumentManager, width:Int, height:Int) {
		this.renderer = renderer;
		this.width = width;
		this.height = height;
		node = new LayoutNode(focus, documents);
		tabs = node.tabs;
	}

	public function openDocument(document:Document):View {
		for (existing in tabs.views)
			if (existing.getDocument() == document) {
				tabs.setActive(existing);
				return existing;
			}
		return tabs.add(new DocumentView(document, renderer, width, height));
	}

	public function resize(width:Int, height:Int):Void {
		this.width = width;
		this.height = height;
		for (view in tabs.views)
			view.resize(width, height);
	}

	public function textInput(text:String):Void {
		if (tabs.activeView != null)
			tabs.activeView.textInput(text);
	}

	public function cursorChanged():Void {
		if (tabs.activeView != null)
			tabs.activeView.cursorChanged();
	}

	public function wheel(vertical:Int, horizontal:Int):Void {
		if (tabs.activeView != null)
			tabs.activeView.wheel(vertical, horizontal);
	}

	public function mouseDown(button:Int, x:Int, y:Int):Void {
		if (button == 1 && y < EditorView.HEADER_HEIGHT && x >= EditorView.SIDEBAR_WIDTH) {
			var index = Std.int((x - EditorView.SIDEBAR_WIDTH) / TAB_WIDTH);
			if (index >= 0 && index < tabs.views.length)
				tabs.setActive(tabs.views[index]);
			return;
		}
		if (tabs.activeView != null)
			tabs.activeView.mouseDown(button, x, y);
	}

	public function mouseMove(x:Int, y:Int):Void {
		if (tabs.activeView != null)
			tabs.activeView.mouseMove(x, y);
	}

	public function mouseUp(button:Int):Void {
		if (tabs.activeView != null)
			tabs.activeView.mouseUp(button);
	}

	public function draw():Void {
		if (tabs.activeView == null) {
			renderer.rect(0, 0, width, height, 0x181818ff);
			return;
		}
		tabs.activeView.draw();
		var x = EditorView.SIDEBAR_WIDTH;
		for (view in tabs.views) {
			var active = view == tabs.activeView;
			renderer.rect(x, 0, TAB_WIDTH, EditorView.HEADER_HEIGHT, active ? 0x303030ff : 0x222222ff);
			renderer.text(x + 12, 13, (view.isDirty() ? "* " : "") + view.title, active ? 0xffffffff : 0xaaaaaaff);
			x += TAB_WIDTH;
		}
	}
}
