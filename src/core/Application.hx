package core;

import command.CommandContext;
import command.CommandRegistry;
import command.EditorCommands;
import command.Keymap;
import editor.Document;
import renderer.Renderer;
import view.RootView;
import view.View;
import plugin.PluginManager;
import plugin.DynamicPlugin;
import plugin.PluginManifest;
import syntax.BuiltinSyntax;
import syntax.SyntaxRegistry;
import style.Theme;
import workspace.Workspace;
import sys.FileSystem;
import commandview.CommandViewEntry;
import commandview.CommandViewProvider;
import platform.Platform;
import search.DocumentSearch;
import search.SearchMatch;
import search.SearchOptions;
import search.WorkspaceSearch;

class Application {
	public final documents:DocumentManager;
	public final workspace:Workspace;
	public final focus:FocusManager;
	public final root:RootView;
	public final commands:CommandRegistry;
	public final keymap:Keymap;
	public final context:CommandContext;
	public final plugins:PluginManager;
	public final syntaxes:SyntaxRegistry;
	public final theme:Theme;
	public final searchOptions:SearchOptions;
	public final documentMatches:Array<SearchMatch> = [];
	public var documentSearchQuery(default, null):String = "";
	var documentMatchIndex:Int = -1;

	public function new(renderer:Renderer, width:Int, height:Int) {
		syntaxes = new SyntaxRegistry();
		BuiltinSyntax.install(syntaxes);
		theme = new Theme();
		workspace = new Workspace(syntaxes);
		documents = workspace.documents;
		focus = new FocusManager();
		root = new RootView(renderer, theme, focus, workspace, width, height);
		commands = new CommandRegistry();
		keymap = new Keymap(commands);
		context = new CommandContext(root, focus, documents);
		EditorCommands.install(commands, keymap);
		searchOptions = new SearchOptions();
		installSearchCommands();
		plugins = new PluginManager(commands, keymap, context, syntaxes);
	}

	public function open(path:String):View
		return root.openDocument(documents.open(path));

	public function openArgument(path:String):Null<View> {
		if (FileSystem.isDirectory(path)) {
			workspace.addProject(path);
			return null;
		}
		return open(path);
	}

	public function add(document:Document):View
		return root.openDocument(documents.add(document));

	public function loadPluginManifest(path:String):Bool
		return plugins.load(new DynamicPlugin(new PluginManifest(path)));

	public function keyPressed(key:Int, modifiers:Int):Bool {
		if (root.commandView.active)
			return root.commandView.keyPressed(key, modifiers);
		if (key == Platform.KEY_P && modifiers == Platform.MOD_CTRL) {
			openFileCommandView();
			return true;
		}
		if (key == Platform.KEY_P && modifiers == Platform.MOD_CTRL + Platform.MOD_SHIFT) {
			openCommandView();
			return true;
		}
		var handled = keymap.onKeyPressed(key, modifiers, context);
		if (handled)
			root.cursorChanged();
		return handled;
	}

	public function textInput(text:String):Void {
		if (root.commandView.active) root.commandView.textInput(text);
		else root.textInput(text);
	}

	public function openFileCommandView():Void {
		var entries:Array<CommandViewEntry> = [];
		for (project in workspace.projects)
			for (node in project.files()) {
				var relative = node.path.substring(project.root.length + 1);
				entries.push(new CommandViewEntry(relative, project.name, node.path));
			}
		root.commandView.open(new CommandViewProvider("", entries, function(query) {}, function(entry, query, backwards) {
			if (entry != null) this.open(entry.value);
			root.commandView.close();
		}));
	}

	public function openCommandView():Void {
		root.commandView.open(new CommandViewProvider("> ",
			[for (name in commands.available(context)) new CommandViewEntry(name, "", name)], function(query) {}, function(entry, query, backwards) {
				root.commandView.close();
				if (entry != null) commands.perform(entry.value, context);
			}));
	}

	public function openDocumentFind():Void {
		if (context.activeView() == null || context.activeView().getDocument() == null) return;
		root.commandView.open(new CommandViewProvider("Find: ", [], refreshDocumentSearch, function(entry, query, backwards) {
			navigateDocumentMatch(backwards ? -1 : 1);
		}, function() {
			root.setDocumentSearchMatches([]);
		}, navigateDocumentMatch));
	}

	public function openWorkspaceFind():Void {
		root.commandView.open(new CommandViewProvider("Search: ", [], function(query) {
			root.showSearchResults(query, WorkspaceSearch.find(workspace, query, searchOptions));
		}, function(entry, query, backwards) {
			if (backwards) root.searchMove(-1);
			root.searchActivate();
			root.commandView.close();
		}, null, function(delta) {
			root.searchMove(delta);
		}));
	}

	public function replaceCurrent(replacement:String):Bool {
		var document = activeDocument(), match = currentDocumentMatch();
		if (document == null || match == null) return false;
		if (!DocumentSearch.replaceCurrent(document, match, replacement)) return false;
		refreshDocumentSearch(documentSearchQuery);
		return true;
	}

	public function replaceAll(replacement:String):Int {
		var document = activeDocument();
		if (document == null) return 0;
		var count = DocumentSearch.replaceAll(document, documentSearchQuery, replacement, searchOptions);
		refreshDocumentSearch(documentSearchQuery);
		return count;
	}

	function openReplace(all:Bool):Void {
		if (documentSearchQuery.length == 0) {
			openDocumentFind();
			return;
		}
		root.commandView.open(new CommandViewProvider(all ? "Replace All: " : "Replace: ", [], function(query) {}, function(entry, replacement, backwards) {
			if (all) replaceAll(replacement); else replaceCurrent(replacement);
			root.commandView.close();
		}));
	}

	function refreshDocumentSearch(query:String):Void {
		documentSearchQuery = query;
		documentMatches.resize(0);
		var document = activeDocument();
		if (document != null)
			for (match in DocumentSearch.find(document, query, searchOptions)) documentMatches.push(match);
		documentMatchIndex = documentMatches.length == 0 ? -1 : 0;
		root.setDocumentSearchMatches(documentMatches);
		if (documentMatchIndex >= 0) selectDocumentMatch();
	}

	function navigateDocumentMatch(delta:Int):Void {
		if (documentMatches.length == 0) return;
		documentMatchIndex += delta;
		if (documentMatchIndex < 0) documentMatchIndex = documentMatches.length - 1;
		if (documentMatchIndex >= documentMatches.length) documentMatchIndex = 0;
		selectDocumentMatch();
	}

	function selectDocumentMatch():Void {
		var document = activeDocument(), match = currentDocumentMatch();
		if (document != null && match != null) {
			DocumentSearch.select(document, match);
			root.cursorChanged();
		}
	}

	function activeDocument():Null<Document> {
		var view = context.activeView();
		return view == null ? null : view.getDocument();
	}

	function currentDocumentMatch():Null<SearchMatch>
		return documentMatchIndex < 0 || documentMatchIndex >= documentMatches.length ? null : documentMatches[documentMatchIndex];

	function installSearchCommands():Void {
		var hasDocument = (context:CommandContext) -> context.activeView() != null && context.activeView().getDocument() != null;
		commands.add("find:open", function(context) {
			openDocumentFind();
		}, hasDocument);
		commands.add("find:next", function(context) {
			navigateDocumentMatch(1);
		}, hasDocument);
		commands.add("find:previous", function(context) {
			navigateDocumentMatch(-1);
		}, hasDocument);
		commands.add("find:replace", function(context) {
			openReplace(false);
		}, hasDocument);
		commands.add("find:replace-all", function(context) {
			openReplace(true);
		}, hasDocument);
		commands.add("find:toggle-case-sensitive", function(context) {
			searchOptions.caseSensitive = !searchOptions.caseSensitive;
			refreshDocumentSearch(documentSearchQuery);
		}, hasDocument);
		commands.add("find:toggle-whole-word", function(context) {
			searchOptions.wholeWord = !searchOptions.wholeWord;
			refreshDocumentSearch(documentSearchQuery);
		}, hasDocument);
		commands.add("workspace:search", function(context) {
			openWorkspaceFind();
		});
		commands.add("workspace:search-next", function(context) {
			root.searchMove(1);
		});
		commands.add("workspace:search-previous", function(context) {
			root.searchMove(-1);
		});
		keymap.addDirect(Platform.KEY_F, Platform.MOD_CTRL, ["find:open"]);
		keymap.addDirect(Platform.KEY_F, Platform.MOD_CTRL + Platform.MOD_SHIFT, ["workspace:search"]);
		keymap.addDirect(Platform.KEY_H, Platform.MOD_CTRL, ["find:replace"]);
	}

	public function update():Void
		plugins.update();

	public function shutdown():Void
		plugins.shutdown();
}
