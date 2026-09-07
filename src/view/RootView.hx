package view;

import core.DocumentManager;
import core.FocusManager;
import editor.Document;
import editor.EditorView;
import renderer.Renderer;
import style.Theme;

class RootView {
	public static inline final TAB_WIDTH = 180;
	public final node:LayoutNode;
	public var tabs(get, never):TabGroup;
	public var activeLeaf(default, null):LayoutNode;
	public final renderer:Renderer;
	public final theme:Theme;
	final focus:FocusManager;
	final documents:DocumentManager;
	var width:Int;
	var height:Int;
	var draggingDivider:Null<LayoutNode>;

	public function new(renderer:Renderer, theme:Theme, focus:FocusManager, documents:DocumentManager, width:Int, height:Int) {
		this.renderer = renderer;
		this.theme = theme;
		this.focus = focus;
		this.documents = documents;
		this.width = width;
		this.height = height;
		node = new LayoutNode(focus, documents);
		activeLeaf = node;
		node.setBounds(0, 0, width, height);
	}

	function get_tabs():TabGroup
		return activeLeaf.tabs;

	public function activateLeaf(leaf:LayoutNode):Void {
		if (!leaf.isLeaf()) throw "only leaf nodes can receive focus";
		activeLeaf = leaf;
		focus.activate(leaf.tabs.activeView);
	}

	public function openDocument(document:Document):View {
		var existing = node.findDocument(document);
		if (existing != null) {
			var leaf = leafForView(node, existing);
			if (leaf != null) activateLeaf(leaf);
			tabs.setActive(existing);
			return existing;
		}
		var view = new DocumentView(document, renderer, theme, activeLeaf.width, activeLeaf.height);
		view.setBounds(activeLeaf.x, activeLeaf.y, activeLeaf.width, activeLeaf.height);
		return tabs.add(view);
	}

	public function splitActive(kind:LayoutKind, newFirst:Bool = false):Bool {
		if (kind == LayoutKind.Leaf) return false;
		var sourceView = tabs.activeView, created = activeLeaf.split(kind, newFirst);
		if (sourceView != null) {
			var document = sourceView.getDocument();
			if (document != null)
				created.tabs.add(new DocumentView(document, renderer, theme, created.width, created.height));
		}
		activateLeaf(created);
		return true;
	}

	public function closeActiveTab(force:Bool = false):Bool {
		var view = tabs.activeView;
		if (view == null || !tabs.close(view, force)) return false;
		var document = view.getDocument();
		if (document != null && !node.containsDocument(document))
			documents.close(document, true);
		return true;
	}

	public function closeActivePane(force:Bool = false):Bool {
		if (activeLeaf == node) return false;
		for (view in activeLeaf.tabs.views)
			if (view.isDirty() && !force) return false;
		var closing = activeLeaf, documentsToCheck:Array<Document> = [];
		for (view in closing.tabs.views) {
			var document = view.getDocument();
			if (document != null) documentsToCheck.push(document);
		}
		if (!node.collapse(closing)) return false;
		activeLeaf = node.firstLeaf();
		focus.activate(activeLeaf.tabs.activeView);
		for (document in documentsToCheck)
			if (!node.containsDocument(document)) documents.close(document, true);
		return true;
	}

	public function resize(width:Int, height:Int):Void {
		this.width = width;
		this.height = height;
		node.setBounds(0, 0, width, height);
	}

	public function textInput(text:String):Void {
		if (tabs.activeView != null) tabs.activeView.textInput(text);
	}

	public function cursorChanged():Void {
		if (tabs.activeView != null) tabs.activeView.cursorChanged();
	}

	public function wheel(vertical:Int, horizontal:Int):Void {
		if (tabs.activeView != null) tabs.activeView.wheel(vertical, horizontal);
	}

	public function mouseDown(button:Int, x:Int, y:Int):Void {
		if (button == 1) {
			var divider = node.dividerAt(x, y);
			if (divider != null) {
				draggingDivider = divider;
				return;
			}
		}
		var leaf = node.leafAt(x, y);
		if (leaf == null) return;
		activateLeaf(leaf);
		if (button == 1 && y < leaf.y + EditorView.HEADER_HEIGHT && x >= leaf.x + EditorView.SIDEBAR_WIDTH) {
			var index = Std.int((x - leaf.x - EditorView.SIDEBAR_WIDTH) / TAB_WIDTH);
			if (index >= 0 && index < tabs.views.length) tabs.setActive(tabs.views[index]);
			return;
		}
		if (tabs.activeView != null) tabs.activeView.mouseDown(button, x, y);
	}

	public function mouseMove(x:Int, y:Int):Void {
		if (draggingDivider != null) {
			draggingDivider.moveDivider(x, y);
			return;
		}
		if (tabs.activeView != null) tabs.activeView.mouseMove(x, y);
	}

	public function mouseUp(button:Int):Void {
		if (button == 1) draggingDivider = null;
		if (tabs.activeView != null) tabs.activeView.mouseUp(button);
	}

	public function draw():Void {
		drawNode(node);
		renderer.clip(0, 0, width, height);
	}

	function drawNode(current:LayoutNode):Void {
		if (current.isLeaf()) {
			drawLeaf(current);
			return;
		}
		drawNode(current.requireFirst());
		renderer.clip(0, 0, width, height);
		drawNode(current.requireSecond());
		renderer.clip(0, 0, width, height);
		var first = current.requireFirst();
		if (current.kind == LayoutKind.Horizontal)
			renderer.rect(first.x + first.width, current.y, LayoutNode.DIVIDER_SIZE, current.height, 0x101010ff);
		else
			renderer.rect(current.x, first.y + first.height, current.width, LayoutNode.DIVIDER_SIZE, 0x101010ff);
	}

	function drawLeaf(leaf:LayoutNode):Void {
		renderer.clip(leaf.x, leaf.y, leaf.width, leaf.height);
		if (leaf.tabs.activeView == null) {
			renderer.rect(leaf.x, leaf.y, leaf.width, leaf.height, 0x181818ff);
			return;
		}
		leaf.tabs.activeView.draw();
		var x = leaf.x + EditorView.SIDEBAR_WIDTH;
		for (view in leaf.tabs.views) {
			var active = view == leaf.tabs.activeView;
			renderer.rect(x, leaf.y, TAB_WIDTH, EditorView.HEADER_HEIGHT, active ? 0x303030ff : 0x222222ff);
			renderer.text(x + 12, leaf.y + 13, (view.isDirty() ? "* " : "") + view.title, active ? 0xffffffff : 0xaaaaaaff);
			x += TAB_WIDTH;
		}
		if (leaf == activeLeaf) renderer.rect(leaf.x, leaf.y, leaf.width, 2, 0x4f8fccff);
	}

	function leafForView(current:LayoutNode, view:View):Null<LayoutNode> {
		if (current.isLeaf()) return current.tabs.indexOf(view) >= 0 ? current : null;
		var found = leafForView(current.requireFirst(), view);
		return found == null ? leafForView(current.requireSecond(), view) : found;
	}
}
