package view;

import core.DocumentManager;
import core.FocusManager;
import editor.Document;
import editor.EditorView;
import renderer.Renderer;
import style.Theme;
import workspace.Workspace;
import commandview.CommandView;
import search.DocumentSearch;
import search.SearchMatch;

class RootView {
	public static inline final TAB_WIDTH = 180;
	public final node:LayoutNode;
	public var tabs(get, never):TabGroup;
	public var activeLeaf(default, null):LayoutNode;
	public final renderer:Renderer;
	public final theme:Theme;
	final focus:FocusManager;
	final documents:DocumentManager;
	public final workspace:Workspace;
	public final sidebar:Sidebar;
	public final searchSidebar:SearchSidebar;
	public final commandView:CommandView;
	public var searchVisible(default, null):Bool = false;
	var width:Int;
	var height:Int;
	var draggingDivider:Null<LayoutNode>;

	public function new(renderer:Renderer, theme:Theme, focus:FocusManager, workspace:Workspace, width:Int, height:Int) {
		this.renderer = renderer;
		this.theme = theme;
		this.focus = focus;
		this.workspace = workspace;
		this.documents = workspace.documents;
		sidebar = new Sidebar(workspace);
		searchSidebar = new SearchSidebar();
		commandView = new CommandView();
		this.width = width;
		this.height = height;
		node = new LayoutNode(focus, documents);
		activeLeaf = node;
		setNodeBounds();
	}

	function get_tabs():TabGroup
		return activeLeaf.tabs;

	public function activateLeaf(leaf:LayoutNode):Void {
		if (!leaf.isLeaf()) throw "only leaf nodes can receive focus";
		activeLeaf = leaf;
		focus.activate(leaf.tabs.activeView);
	}

	public function openDocument(document:Document):View {
		sidebar.selectPath(document.path);
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
		setNodeBounds();
	}

	public function setSidebarWidth(width:Int):Void {
		sidebar.width = width;
		setNodeBounds();
	}

	function setNodeBounds():Void {
		var contentWidth = width - sidebar.width;
		if (contentWidth < 0) contentWidth = 0;
		node.setBounds(sidebar.width, 0, contentWidth, height);
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
		if (button == 1 && x < sidebar.width) {
			if (searchVisible) {
				var match = searchSidebar.mouseDown(x, y);
				if (match != null) openSearchMatch(match);
			} else {
				var path = sidebar.mouseDown(x, y);
				if (path != null) openDocument(documents.open(path));
			}
			return;
		}
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
		if (button == 1 && y < leaf.y + EditorView.HEADER_HEIGHT) {
			var index = Std.int((x - leaf.x) / TAB_WIDTH);
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
		if (searchVisible) searchSidebar.draw(renderer, height); else sidebar.draw(renderer, height);
		renderer.clip(0, 0, width, height);
		drawNode(node);
		renderer.clip(0, 0, width, height);
		commandView.draw(renderer, width, height);
	}

	public function showSearchResults(query:String, results:Array<SearchMatch>):Void {
		searchVisible = true;
		searchSidebar.setResults(query, results);
	}

	public function showProjectSidebar():Void
		searchVisible = false;

	public function searchMove(delta:Int):Bool
		return searchSidebar.selectBy(delta);

	public function searchActivate():Bool {
		var match = searchSidebar.active();
		if (match != null) openSearchMatch(match);
		return true;
	}

	public function openSearchMatch(match:SearchMatch):Void {
		var view = openDocument(documents.open(match.path));
		var document = view.getDocument();
		if (document != null) {
			DocumentSearch.select(document, match);
			view.cursorChanged();
		}
	}

	public function setDocumentSearchMatches(results:Array<SearchMatch>):Void {
		var view = tabs.activeView;
		if (view == null) return;
		view.setSearchMatches(results);
	}

	public function sidebarMove(delta:Int):Bool
		return sidebar.selectBy(delta);

	public function sidebarActivate():Bool {
		var path = sidebar.activate();
		if (path == null) return true;
		openDocument(documents.open(path));
		return true;
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
			renderer.rect(leaf.x, leaf.y, leaf.width, leaf.height, theme.editorBackground);
			return;
		}
		leaf.tabs.activeView.draw();
		var x = leaf.x;
		for (view in leaf.tabs.views) {
			var active = view == leaf.tabs.activeView;
			renderer.rect(x, leaf.y, TAB_WIDTH, EditorView.HEADER_HEIGHT, active ? 0x303030ff : 0x222222ff);
			renderer.text(x + 12, leaf.y + 13, (view.isDirty() ? "* " : "") + view.title, active ? 0xffffffff : 0xaaaaaaff);
			x += TAB_WIDTH;
		}
		if (leaf == activeLeaf) renderer.rect(leaf.x, leaf.y, leaf.width, 2, theme.accent);
	}

	function leafForView(current:LayoutNode, view:View):Null<LayoutNode> {
		if (current.isLeaf()) return current.tabs.indexOf(view) >= 0 ? current : null;
		var found = leafForView(current.requireFirst(), view);
		return found == null ? leafForView(current.requireSecond(), view) : found;
	}
}
