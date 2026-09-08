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
import syntax.BuiltinSyntax;
import syntax.SyntaxRegistry;
import style.Theme;
import workspace.Workspace;
import workspace.FileOperations;
import workspace.TrashService;
import sys.FileSystem;
import commandview.CommandViewEntry;
import commandview.CommandViewProvider;
import platform.Platform;
import search.SearchMatch;
import search.SearchOptions;
import search.WorkspaceSearch;
import search.WorkspaceReplacement;
import search.ReplacementPreview;
import search.ReplacementResult;
import command.KeyBinding;
import config.ConfigurationPaths;
import config.Settings;
import config.SettingsService;
import recovery.RecoveryStore;
import recovery.RecoverySnapshot;
import feedback.ErrorLog;
import feedback.ConfirmationService;
import feedback.NotificationKind;
import completion.CompletionRegistry;
import completion.DocumentWordCompletionProvider;
import controller.SearchController;
import controller.FileController;
import controller.ConfigurationController;
import controller.PluginController;

class Application {
	public final documents:DocumentManager;
	public final workspace:Workspace;
	public final fileOperations:FileOperations;
	public final focus:FocusManager;
	public final root:RootView;
	public final commands:CommandRegistry;
	public final keymap:Keymap;
	public final context:CommandContext;
	public final plugins:PluginManager;
	public final pluginController:PluginController;
	public final syntaxes:SyntaxRegistry;
	public final completions:CompletionRegistry;
	public final theme:Theme;
	public final search:SearchController;
	public final files:FileController;
	public final configuration:ConfigurationController;
	public final searchOptions:SearchOptions;
	public final workspaceSearch:WorkspaceSearch;
	public final workspaceReplacement:WorkspaceReplacement;
	public var replacementPreview(get, never):Null<ReplacementPreview>;
	public var replacementResult(get, never):Null<ReplacementResult>;
	public final settings:SettingsService;
	public final recovery:RecoveryStore;
	public final errors:ErrorLog;
	public final confirmations:ConfirmationService;
	public final documentMatches:Array<SearchMatch>;
	public var documentSearchQuery(get, never):String;
	var lastFileSystemCheck:Float = 0.0;
	public var quitReady(get, never):Bool;

	public function new(renderer:Renderer, width:Int, height:Int, ?settings:SettingsService) {
		this.settings = settings == null ? new SettingsService() : settings;
		recovery = new RecoveryStore(ConfigurationPaths.recovery());
		syntaxes = new SyntaxRegistry();
		BuiltinSyntax.install(syntaxes);
		completions = new CompletionRegistry();
		completions.add("core", new DocumentWordCompletionProvider());
		theme = new Theme();
		workspace = new Workspace(syntaxes);
		fileOperations = new FileOperations(workspace, new TrashService(ConfigurationPaths.trash(), workspace.fileSystem));
		documents = workspace.documents;
		focus = new FocusManager();
		root = new RootView(renderer, theme, focus, workspace, width, height, this.settings.current);
		errors = new ErrorLog();
		confirmations = new ConfirmationService(root.commandView);
		root.closeRequest = function() {
			requestCloseActiveTab();
		};
		commands = new CommandRegistry();
		keymap = new Keymap(commands);
		context = new CommandContext(root, focus, documents);
		EditorCommands.install(commands, keymap);
		search = new SearchController(workspace, root, context, commands, keymap, confirmations, effectiveSettings, reportError,
			reportInformation, ConfigurationPaths.replacementBackup());
		searchOptions = search.options;
		workspaceSearch = search.workspaceSearch;
		workspaceReplacement = search.workspaceReplacement;
		documentMatches = search.documentMatches;
		configuration = new ConfigurationController(this.settings, workspace, root, context, commands, keymap, theme, search, reportError);
		files = new FileController(documents, workspace, fileOperations, root, context, commands, confirmations, recovery,
			path -> { open(path); }, function() { newDocument(); }, function() { recovery.save(this); }, reportError, reportInformation);
		pluginController = new PluginController(commands, keymap, context, syntaxes, completions, root.pluginPanels, workspace.jobs,
			effectiveSettings, root, reportError, reportInformation);
		plugins = pluginController.manager;
		installWorkbenchCommands();
		commands.add("recovery:open", context -> openRecoveryCommandView());
	}

	public function open(path:String):View
		return root.openDocument(documents.open(path));

	public function openArgument(path:String):Null<View> {
		if (FileSystem.isDirectory(path)) {
			var normalized = workspace.fileSystem.normalize(path);
			var projectSettings = settings.forProject(ConfigurationPaths.projectSettings(normalized));
			var project = workspace.addProject(normalized, projectSettings.current.excludedNames);
			project.setSettings(projectSettings);
			configuration.apply(projectSettings.current);
			return null;
		}
		return open(path);
	}

	public function add(document:Document):View
		return root.openDocument(documents.add(document));

	public function newDocument():View
		return root.openDocument(documents.createUntitled());

	public function loadPluginManifest(path:String):Bool
		return pluginController.loadManifest(path);

	public function keyPressed(key:Int, modifiers:Int):Bool {
		if (root.commandView.active)
			return root.commandView.keyPressed(key, modifiers);
		var handled = keymap.onKeyPressed(key, modifiers, context);
		if (handled)
			root.cursorChanged();
		if (handled) search.editorStateChanged();
		return handled;
	}

	public function textInput(text:String):Void {
		if (root.commandView.active) root.commandView.textInput(text);
		else {
			root.textInput(text);
			search.editorStateChanged();
		}
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
		}, null, null, function(query, entry) {
			return entry == null ? query : entry.label;
		}));
	}

	public function openCommandView():Void {
		root.commandView.open(new CommandViewProvider("> ",
			[for (name in commands.available(context)) new CommandViewEntry(name, "", name)], function(query) {}, function(entry, query, backwards) {
				root.commandView.close();
				if (entry != null) commands.perform(entry.value, context);
			}));
	}

	public function openCompletionCommandView():Void {
		var view = context.activeView(), document = activeDocument(), selection = activeSelection();
		if (view == null || document == null || selection == null) return;
		var result = completions.request(document, selection.cursor), revision = document.buffer.stateId,
			entries = [for (item in result.items) new CommandViewEntry(item.label, item.detail, item.insertText)];
		if (entries.length == 0) return;
		root.commandView.open(new CommandViewProvider("Complete: ", entries, function(query) {}, function(entry, query, backwards) {
			root.commandView.close();
			if (entry == null || activeDocument() != document || document.buffer.stateId != revision || !selection.cursor.equals(result.replaceTo)) return;
			if (view.replaceRange(result.replaceFrom, result.replaceTo, entry.value)) view.cursorChanged();
		}));
	}

	public function openGoToLine():Void {
		if (activeDocument() == null) return;
		root.commandView.open(new CommandViewProvider("Go to Line: ", [], function(query) {}, function(entry, query, backwards) {
			var fields = query.split(":"), line = fields.length > 0 ? Std.parseInt(fields[0]) : 0,
				column = fields.length > 1 ? Std.parseInt(fields[1]) : 1, view = context.activeView();
			if (view != null && line > 0 && column > 0) {
				view.restoreCursor(line - 1, column - 1);
				view.cursorChanged();
			}
			root.commandView.close();
		}));
	}

	public function openDocumentFind():Void {
		search.openDocumentFind();
	}

	public function openWorkspaceFind():Void {
		search.openWorkspaceFind();
	}

	public function previewWorkspaceReplacement(replacement:String):Bool
		return search.previewWorkspaceReplacement(replacement);

	public function applyWorkspaceReplacement():Bool
		return search.applyWorkspaceReplacement();

	public function replaceCurrent(replacement:String):Bool
		return search.replaceCurrent(replacement);

	public function replaceAll(replacement:String):Int
		return search.replaceAll(replacement);

	function get_replacementPreview():Null<ReplacementPreview>
		return search.replacementPreview;

	function get_replacementResult():Null<ReplacementResult>
		return search.replacementResult;

	function get_documentSearchQuery():String
		return search.documentSearchQuery;

	function activeDocument():Null<Document> {
		var view = context.activeView();
		return view == null ? null : view.getDocument();
	}

	function activeSelection():Null<editor.BufferSelection> {
		var view = context.activeView();
		return view == null ? null : view.getSelection();
	}

	function installWorkbenchCommands():Void {
		commands.add("files:open", function(context) {
			openFileCommandView();
		});
		commands.add("commands:open", function(context) {
			openCommandView();
		});
		commands.add("navigation:go-to-line", context -> openGoToLine(), context -> activeDocument() != null);
		commands.add("doc:complete-word", context -> openCompletionCommandView(), context -> activeDocument() != null);
		commands.add("layout:focus-left", context -> root.focusPane(-1, 0));
		commands.add("layout:focus-right", context -> root.focusPane(1, 0));
		commands.add("layout:focus-up", context -> root.focusPane(0, -1));
		commands.add("layout:focus-down", context -> root.focusPane(0, 1));
		commands.add("layout:move-tab-left", context -> root.moveActiveTab(-1, 0));
		commands.add("layout:move-tab-right", context -> root.moveActiveTab(1, 0));
		commands.add("layout:move-tab-up", context -> root.moveActiveTab(0, -1));
		commands.add("layout:move-tab-down", context -> root.moveActiveTab(0, 1));
		commands.add("layout:reorder-tab-left", context -> root.reorderActiveTab(-1));
		commands.add("layout:reorder-tab-right", context -> root.reorderActiveTab(1));
		commands.add("workbench:toggle-sidebar", context -> root.toggleSidebar());
		commands.add("workbench:show-errors", context -> openErrorLog());
		commands.add("workbench:clear-notifications", function(context) {
			root.notifications.clear();
		});
		commands.add("doc:newline", context -> context.requireView().insertNewline(), context -> activeDocument() != null);
		commands.add("doc:duplicate-line", context -> context.requireView().duplicateLines(), context -> activeDocument() != null);
		commands.add("doc:move-line-up", context -> context.requireView().moveLines(-1), context -> activeDocument() != null);
		commands.add("doc:move-line-down", context -> context.requireView().moveLines(1), context -> activeDocument() != null);
		commands.add("doc:delete-line", context -> context.requireView().deleteLines(), context -> activeDocument() != null);
		commands.add("doc:join-lines", context -> context.requireView().joinLines(), context -> activeDocument() != null);
		commands.add("doc:toggle-line-comment", context -> context.requireView().toggleLineComment(), context -> activeDocument() != null);
		commands.add("doc:select-next-occurrence", context -> context.requireView().selectNextOccurrence(), context -> activeDocument() != null);
		keymap.addDirect(Platform.KEY_TAB, Platform.MOD_SHIFT, ["doc:unindent"]);
		keymap.addDirect(Platform.KEY_DOWN, Platform.MOD_ALT + Platform.MOD_SHIFT, ["doc:duplicate-line"]);
		keymap.addDirect(Platform.KEY_UP, Platform.MOD_ALT, ["doc:move-line-up"]);
		keymap.addDirect(Platform.KEY_DOWN, Platform.MOD_ALT, ["doc:move-line-down"]);
		keymap.addDirect(Platform.KEY_K, Platform.MOD_CTRL + Platform.MOD_SHIFT, ["doc:delete-line"]);
		keymap.addDirect(Platform.KEY_J, Platform.MOD_CTRL, ["doc:join-lines"]);
		keymap.addDirect(Platform.KEY_SLASH, Platform.MOD_CTRL, ["doc:toggle-line-comment"]);
		keymap.addDirect(Platform.KEY_D, Platform.MOD_CTRL, ["doc:select-next-occurrence"]);
		keymap.addDirect(Platform.KEY_P, Platform.MOD_CTRL, ["files:open"]);
		keymap.addDirect(Platform.KEY_P, Platform.MOD_CTRL + Platform.MOD_SHIFT, ["commands:open"]);
		keymap.addDirect(Platform.KEY_G, Platform.MOD_CTRL, ["navigation:go-to-line"]);
		keymap.addDirect(Platform.KEY_SPACE, Platform.MOD_CTRL, ["doc:complete-word"]);
		keymap.addDirect(Platform.KEY_LEFT, Platform.MOD_CTRL + Platform.MOD_ALT, ["layout:focus-left"]);
		keymap.addDirect(Platform.KEY_RIGHT, Platform.MOD_CTRL + Platform.MOD_ALT, ["layout:focus-right"]);
		keymap.addDirect(Platform.KEY_UP, Platform.MOD_CTRL + Platform.MOD_ALT, ["layout:focus-up"]);
		keymap.addDirect(Platform.KEY_DOWN, Platform.MOD_CTRL + Platform.MOD_ALT, ["layout:focus-down"]);
		keymap.addDirect(Platform.KEY_LEFT, Platform.MOD_CTRL + Platform.MOD_SHIFT + Platform.MOD_ALT, ["layout:move-tab-left"]);
		keymap.addDirect(Platform.KEY_RIGHT, Platform.MOD_CTRL + Platform.MOD_SHIFT + Platform.MOD_ALT, ["layout:move-tab-right"]);
		keymap.addDirect(Platform.KEY_UP, Platform.MOD_CTRL + Platform.MOD_SHIFT + Platform.MOD_ALT, ["layout:move-tab-up"]);
		keymap.addDirect(Platform.KEY_DOWN, Platform.MOD_CTRL + Platform.MOD_SHIFT + Platform.MOD_ALT, ["layout:move-tab-down"]);
		keymap.addDirect(Platform.KEY_PAGE_UP, Platform.MOD_CTRL, ["layout:reorder-tab-left"]);
		keymap.addDirect(Platform.KEY_PAGE_DOWN, Platform.MOD_CTRL, ["layout:reorder-tab-right"]);
		keymap.addDirect(Platform.KEY_B, Platform.MOD_CTRL, ["workbench:toggle-sidebar"]);
	}

	public function requestCloseActiveTab():Bool
		return files.requestCloseActiveTab();

	public function requestCloseActivePane():Bool
		return files.requestCloseActivePane();

	public function requestQuit():Bool
		return files.requestQuit();

	function get_quitReady():Bool
		return files.quitReady;

	public function openSaveAs(document:Document, ?onSuccess:Void->Void):Void
		files.openSaveAs(document, onSuccess);

	public function openCreateFile():Void
		files.openCreateFile();

	public function openCreateFolder():Void
		files.openCreateFolder();

	public function openRenameFile():Void
		files.openRenameFile();

	public function openDeleteFile():Void
		files.openDeleteFile();

	public function openSettingsCommandView():Void
		configuration.openSettingsCommandView();

	public function openKeybindingsCommandView():Void
		configuration.openKeybindingsCommandView();

	public function openErrorLog():Void {
		var entries:Array<CommandViewEntry> = [];
		for (error in errors.entries)
			entries.unshift(new CommandViewEntry(error.source, error.message, error.source + ": " + error.message));
		root.commandView.open(new CommandViewProvider("Errors: ", entries, function(query) {}, function(entry, query, backwards) {
			root.commandView.close();
		}));
	}

	public function openRecoveryCommandView():Bool {
		var snapshots = recovery.load(), entries:Array<CommandViewEntry> = [];
		for (index in 0...snapshots.length)
			entries.push(new CommandViewEntry(snapshots[index].title, "Recovered unsaved buffer", Std.string(index)));
		for (diagnostic in recovery.diagnostics) reportError("recovery", diagnostic);
		if (entries.length == 0) return false;
		root.commandView.open(new CommandViewProvider("Recover: ", entries, function(query) {}, function(entry, query, backwards) {
			if (entry != null) {
				var selected = Std.parseInt(entry.value);
				if (selected >= 0 && selected < snapshots.length && recovery.restore(this, snapshots[selected])) {
					recovery.forgetSnapshot(snapshots[selected]);
					recovery.save(this);
				}
			}
			root.commandView.close();
		}));
		return true;
	}

	public function update():Void {
		var now = Sys.time();
		configuration.update();
		search.update(now);
		workspace.jobs.update(32);
		if (now - lastFileSystemCheck >= 1.0) {
			lastFileSystemCheck = now;
			documents.checkExternalChanges();
			workspace.refreshProjects();
		}
		pluginController.update(now);
	}

	function effectiveSettings():Settings
		return configuration.effectiveSettings();

	public function reportInformation(message:String):Void
		root.notifications.publish(message, NotificationKind.Information);

	public function reportError(source:String, message:String):Void {
		errors.record(source, message);
		root.notifications.publish(message, NotificationKind.Error);
	}

	public function shutdown():Void {
		configuration.shutdown();
		pluginController.shutdown();
	}
}
