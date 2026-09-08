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
import command.KeyBinding;
import config.ConfigurationPaths;
import config.Settings;
import config.SettingsService;

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
	public final settings:SettingsService;
	public final documentMatches:Array<SearchMatch> = [];
	public var documentSearchQuery(default, null):String = "";
	var documentMatchIndex:Int = -1;
	var settingsListener:Settings->Void;

	public function new(renderer:Renderer, width:Int, height:Int, ?settings:SettingsService) {
		this.settings = settings == null ? new SettingsService() : settings;
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
		installConfigurationCommands();
		settingsListener = applySettings;
		this.settings.subscribe(settingsListener);
	}

	public function open(path:String):View
		return root.openDocument(documents.open(path));

	public function openArgument(path:String):Null<View> {
		if (FileSystem.isDirectory(path)) {
			var normalized = workspace.fileSystem.normalize(path);
			settings.addProject(ConfigurationPaths.projectSettings(normalized));
			workspace.addProject(normalized, settings.current.excludedNames);
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
			root.showSearchResults(query, WorkspaceSearch.find(workspace, query, searchOptions, settings.current.searchMaxResults));
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

	function installConfigurationCommands():Void {
		commands.add("files:open", function(context) {
			openFileCommandView();
		});
		commands.add("commands:open", function(context) {
			openCommandView();
		});
		commands.add("settings:reload", function(context) {
			settings.reload(true);
		});
		commands.add("settings:open", function(context) {
			openSettingsCommandView();
		});
		commands.add("keybindings:open", function(context) {
			openKeybindingsCommandView();
		});
		commands.add("doc:indent", function(context) {
			var spaces = "";
			for (index in 0...settings.current.tabWidth) spaces += " ";
			context.requireDocument().insert(spaces);
		}, function(context) return context.activeView() != null && context.activeView().getDocument() != null);
		keymap.addDirect(Platform.KEY_P, Platform.MOD_CTRL, ["files:open"]);
		keymap.addDirect(Platform.KEY_P, Platform.MOD_CTRL + Platform.MOD_SHIFT, ["commands:open"]);
	}

	public function openSettingsCommandView():Void {
		var value = settings.current, entries = [
			new CommandViewEntry("editor.fontPath", value.fontPath, "editor.fontPath"),
			new CommandViewEntry("editor.fontSize", Std.string(value.fontSize), "editor.fontSize"),
			new CommandViewEntry("editor.tabWidth", Std.string(value.tabWidth), "editor.tabWidth"),
			new CommandViewEntry("workbench.sidebarWidth", Std.string(value.sidebarWidth), "workbench.sidebarWidth"),
			new CommandViewEntry("search.maxResults", Std.string(value.searchMaxResults), "search.maxResults")
		];
		for (diagnostic in settings.diagnostics) entries.unshift(new CommandViewEntry("Configuration error", diagnostic, diagnostic));
		root.commandView.open(new CommandViewProvider("Settings: ", entries, function(query) {}, function(entry, query, backwards) {
			root.commandView.close();
		}));
	}

	public function openKeybindingsCommandView():Void {
		var entries:Array<CommandViewEntry> = [];
		for (binding in settings.current.keybindings)
			entries.push(new CommandViewEntry(keyName(binding.key, binding.modifiers), binding.commands.join(", "), binding.commands[0]));
		root.commandView.open(new CommandViewProvider("Keybindings: ", entries, function(query) {}, function(entry, query, backwards) {
			root.commandView.close();
		}));
	}

	function applySettings(value:Settings):Void {
		theme.editorBackground = value.editorBackground;
		theme.editorForeground = value.editorForeground;
		theme.accent = value.accent;
		searchOptions.caseSensitive = value.searchCaseSensitive;
		searchOptions.wholeWord = value.searchWholeWord;
		root.setSidebarWidth(value.sidebarWidth);
		for (project in workspace.projects) project.setIgnored(value.excludedNames);
		keymap.setConfigured([for (binding in value.keybindings) new KeyBinding(binding.key, binding.modifiers, binding.commands)]);
		if (!root.renderer.reloadFont(value.fontPath, value.fontSize))
			settings.diagnostics.push('could not load font "' + value.fontPath + '"');
	}

	function keyName(key:Int, modifiers:Int):String {
		var result = "";
		if (modifiers & Platform.MOD_CTRL != 0) result += "Ctrl+";
		if (modifiers & Platform.MOD_SHIFT != 0) result += "Shift+";
		return result + Std.string(key);
	}

	public function update():Void {
		settings.reload();
		plugins.update();
	}

	public function shutdown():Void {
		settings.unsubscribe(settingsListener);
		plugins.shutdown();
	}
}
