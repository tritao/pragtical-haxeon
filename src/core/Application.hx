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
import recovery.RecoveryStore;
import recovery.RecoverySnapshot;

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
	public final recovery:RecoveryStore;
	public final documentMatches:Array<SearchMatch> = [];
	public var documentSearchQuery(default, null):String = "";
	var documentMatchIndex:Int = -1;
	var documentSearchDocument:Null<Document>;
	var documentSearchRevision:Int = -1;
	var settingsListener:Settings->Void;
	var lastFileSystemCheck:Float = 0.0;
	public final messages:Array<String> = [];
	public var quitReady(default, null):Bool = false;
	var closeDocuments:Array<Document> = [];
	var closeIndex:Int = 0;
	var closeAction:Null<Void->Bool>;
	var closePending:Bool = false;

	public function new(renderer:Renderer, width:Int, height:Int, ?settings:SettingsService) {
		this.settings = settings == null ? new SettingsService() : settings;
		recovery = new RecoveryStore(ConfigurationPaths.recovery());
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
		installFileCommands();
		commands.add("recovery:open", context -> openRecoveryCommandView());
		settingsListener = applySettings;
		this.settings.subscribe(settingsListener);
	}

	public function open(path:String):View
		return root.openDocument(documents.open(path));

	public function openArgument(path:String):Null<View> {
		if (FileSystem.isDirectory(path)) {
			var normalized = workspace.fileSystem.normalize(path);
			var projectSettings = settings.forProject(ConfigurationPaths.projectSettings(normalized));
			var project = workspace.addProject(normalized, projectSettings.current.excludedNames);
			project.settings = projectSettings;
			return null;
		}
		return open(path);
	}

	public function add(document:Document):View
		return root.openDocument(documents.add(document));

	public function newDocument():View
		return root.openDocument(documents.createUntitled());

	public function loadPluginManifest(path:String):Bool
		return plugins.load(new DynamicPlugin(new PluginManifest(path)));

	public function keyPressed(key:Int, modifiers:Int):Bool {
		if (root.commandView.active)
			return root.commandView.keyPressed(key, modifiers);
		var handled = keymap.onKeyPressed(key, modifiers, context);
		if (handled)
			root.cursorChanged();
		if (handled && documentSearchQuery.length > 0) ensureDocumentSearchFresh();
		return handled;
	}

	public function textInput(text:String):Void {
		if (root.commandView.active) root.commandView.textInput(text);
		else {
			root.textInput(text);
			if (documentSearchQuery.length > 0) ensureDocumentSearchFresh();
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
		documentSearchDocument = document;
		documentSearchRevision = document == null ? -1 : document.buffer.stateId;
		if (document != null)
			for (match in DocumentSearch.find(document, query, searchOptions)) documentMatches.push(match);
		documentMatchIndex = documentMatches.length == 0 ? -1 : 0;
		root.setDocumentSearchMatches(documentMatches);
		if (documentMatchIndex >= 0) selectDocumentMatch();
	}

	function navigateDocumentMatch(delta:Int):Void {
		ensureDocumentSearchFresh();
		if (documentMatches.length == 0) return;
		documentMatchIndex += delta;
		if (documentMatchIndex < 0) documentMatchIndex = documentMatches.length - 1;
		if (documentMatchIndex >= documentMatches.length) documentMatchIndex = 0;
		selectDocumentMatch();
	}

	function selectDocumentMatch():Void {
		var document = activeDocument(), match = currentDocumentMatch();
		if (document != null && match != null) {
			if (DocumentSearch.select(document, match)) root.cursorChanged();
		}
	}

	function ensureDocumentSearchFresh():Void {
		var document = activeDocument();
		if (document != documentSearchDocument || document != null && document.buffer.stateId != documentSearchRevision)
			refreshDocumentSearch(documentSearchQuery);
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
		commands.add("project:show-sidebar", function(context) {
			root.showProjectSidebar();
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
			var value = settings.current, document = context.requireDocument(), matchedLength = -1;
			for (project in workspace.projects)
				if (document.path != null && project.settings != null && StringTools.startsWith(document.path, project.root + "/") && project.root.length > matchedLength) {
					value = project.settings.current;
					matchedLength = project.root.length;
				}
			for (index in 0...value.tabWidth) spaces += " ";
			context.requireDocument().insert(spaces);
		}, function(context) return context.activeView() != null && context.activeView().getDocument() != null);
		keymap.addDirect(Platform.KEY_P, Platform.MOD_CTRL, ["files:open"]);
		keymap.addDirect(Platform.KEY_P, Platform.MOD_CTRL + Platform.MOD_SHIFT, ["commands:open"]);
	}

	function installFileCommands():Void {
		commands.add("doc:save", function(context) {
			var document = context.requireDocument();
			if (!document.hasBackingPath()) {
				openSaveAs(document);
				return;
			}
			if (!document.save()) {
				messages.push('Save blocked for "' + document.path + '": disk changed or write failed');
				if (document.externalState != editor.ExternalState.Current) confirmOverwrite(document);
			}
			else recovery.forget(document);
		}, context -> activeDocument() != null);
		commands.add("file:new", context -> openCreateFile());
		commands.add("doc:new", context -> newDocument());
		commands.add("doc:save-as", context -> openSaveAs(context.requireDocument()), context -> activeDocument() != null);
		commands.add("root:close", context -> requestCloseActiveTab(), context -> context.activeView() != null);
		commands.add("root:close-pane", context -> requestCloseActivePane());
		commands.add("folder:new", context -> openCreateFolder());
		commands.add("file:rename", context -> openRenameFile(), context -> activeDocument() != null);
		commands.add("file:delete", context -> openDeleteFile(), context -> activeDocument() != null);
	}

	public function requestCloseActiveTab():Bool
		return beginClose(root.documentsLostByClosingActiveTab(), function() return root.closeActiveTab(true));

	public function requestCloseActivePane():Bool {
		if (root.activeLeaf == root.node) return false;
		return beginClose(root.documentsLostByClosingActivePane(), function() return root.closeActivePane(true));
	}

	public function requestQuit():Bool {
		if (quitReady) return true;
		var dirty:Array<Document> = [];
		for (document in documents.documents) if (document.dirty && dirty.indexOf(document) < 0) dirty.push(document);
		return beginClose(dirty, function() {
			quitReady = true;
			return true;
		});
	}

	function beginClose(candidates:Array<Document>, action:Void->Bool):Bool {
		if (closePending) return false;
		closeDocuments.resize(0);
		for (document in candidates) if (document.dirty && closeDocuments.indexOf(document) < 0) closeDocuments.push(document);
		closeIndex = 0;
		closeAction = action;
		closePending = true;
		continueClose();
		return true;
	}

	function continueClose():Void {
		if (!closePending) return;
		if (closeIndex >= closeDocuments.length) {
			var action = closeAction;
			closePending = false;
			closeAction = null;
			root.commandView.close();
			if (action != null) action();
			return;
		}
		var document = closeDocuments[closeIndex];
		root.commandView.open(new CommandViewProvider('Save changes to "' + document.title + '"? Type save, discard, or cancel: ', [],
			function(query) {}, function(entry, answer, backwards) {
				if (answer == "cancel") cancelClose();
				else if (answer == "discard") {
						recovery.forget(document);
						closeIndex++;
						continueClose();
				} else if (answer == "save") {
						if (document.hasBackingPath()) {
							if (!document.save()) {
								messages.push('Could not save "' + document.title + '"; close cancelled');
								cancelClose();
							} else {
								recovery.forget(document);
								closeIndex++;
								continueClose();
							}
						} else openSaveAs(document, function() {
							closeIndex++;
							continueClose();
						});
				}
			}));
	}

	function cancelClose():Void {
		closePending = false;
		closeDocuments.resize(0);
		closeAction = null;
		root.commandView.close();
	}

	public function openSaveAs(document:Document, ?onSuccess:Void->Void):Void {
		root.commandView.open(new CommandViewProvider("Save As: ", [], function(query) {}, function(entry, destination, backwards) {
			if (documents.saveAs(document, destination)) {
				root.documentRenamed(document);
				recovery.forget(document);
				root.commandView.close();
				if (onSuccess != null) onSuccess();
			} else if (workspace.fileSystem.exists(destination)) {
				root.commandView.open(new CommandViewProvider('Type overwrite to replace "$destination": ', [], function(query) {},
					function(entry, answer, backwards) {
						if (answer == "overwrite" && documents.saveAs(document, destination, true)) {
							root.documentRenamed(document);
							recovery.forget(document);
							root.commandView.close();
							if (onSuccess != null) onSuccess();
						}
					}));
			} else {
				messages.push('Could not save as "$destination"');
				root.commandView.close();
			}
		}));
	}

	public function openCreateFile():Void {
		root.commandView.open(new CommandViewProvider("New File: ", [], function(query) {}, function(entry, path, backwards) {
			if (workspace.fileSystem.createFile(path)) {
				workspace.refreshProjects();
				open(path);
			} else messages.push('Could not create file "$path"');
			root.commandView.close();
		}));
	}

	function confirmOverwrite(document:Document):Void {
		root.commandView.open(new CommandViewProvider("Disk changed. Type overwrite to save, or Escape to cancel: ", [], function(query) {}, function(entry, answer, backwards) {
			if (answer != "overwrite") return;
			if (document.save(true)) {
				recovery.forget(document);
				messages.push("Saved " + document.path);
			} else messages.push("Could not save " + document.path);
			root.commandView.close();
		}));
	}

	public function openCreateFolder():Void {
		root.commandView.open(new CommandViewProvider("New Folder: ", [], function(query) {}, function(entry, path, backwards) {
			if (!workspace.fileSystem.createFolder(path)) messages.push('Could not create folder "$path"');
			workspace.refreshProjects();
			root.commandView.close();
		}));
	}

	public function openRenameFile():Void {
		var document = activeDocument();
		if (document == null || !document.hasBackingPath()) return;
		root.commandView.open(new CommandViewProvider("Rename/Move: ", [], function(query) {}, function(entry, destination, backwards) {
			if (!documents.rename(document, destination)) messages.push('Could not rename "' + document.path + '"');
			else root.documentRenamed(document);
			workspace.refreshProjects();
			root.commandView.close();
		}));
	}

	public function openDeleteFile():Void {
		var document = activeDocument();
		if (document == null || !document.hasBackingPath()) return;
		var path = document.requirePath();
		root.commandView.open(new CommandViewProvider('Type delete to remove "' + path + '": ', [], function(query) {}, function(entry, answer, backwards) {
			if (answer == "delete" && !document.dirty && workspace.fileSystem.deleteFile(path)) {
				root.closeActiveTab(true);
				workspace.refreshProjects();
			} else if (answer == "delete") messages.push('Could not safely delete "' + path + '"');
			root.commandView.close();
		}));
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

	public function openRecoveryCommandView():Bool {
		var snapshots = recovery.load(), entries:Array<CommandViewEntry> = [];
		for (index in 0...snapshots.length)
			entries.push(new CommandViewEntry(snapshots[index].title, "Recovered unsaved buffer", Std.string(index)));
		for (diagnostic in recovery.diagnostics) messages.push(diagnostic);
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

	function applySettings(value:Settings):Void {
		theme.editorBackground = value.editorBackground;
		theme.editorForeground = value.editorForeground;
		theme.accent = value.accent;
		searchOptions.caseSensitive = value.searchCaseSensitive;
		searchOptions.wholeWord = value.searchWholeWord;
		root.setSidebarWidth(value.sidebarWidth);
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
		if (Sys.time() - lastFileSystemCheck >= 1.0) {
			lastFileSystemCheck = Sys.time();
			documents.checkExternalChanges();
			workspace.refreshProjects();
		}
		plugins.update();
		if (messages.length > 0) root.notification = messages[messages.length - 1];
	}

	public function shutdown():Void {
		settings.unsubscribe(settingsListener);
		plugins.shutdown();
	}
}
