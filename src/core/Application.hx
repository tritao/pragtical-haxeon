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
import workspace.FileOperations;
import workspace.TrashService;
import sys.FileSystem;
import commandview.CommandViewEntry;
import commandview.CommandViewProvider;
import platform.Platform;
import search.DocumentSearch;
import search.SearchMatch;
import search.SearchOptions;
import search.WorkspaceSearch;
import search.WorkspaceReplacement;
import search.ReplacementBackupStore;
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
	public final syntaxes:SyntaxRegistry;
	public final completions:CompletionRegistry;
	public final theme:Theme;
	public final searchOptions:SearchOptions;
	public final workspaceSearch:WorkspaceSearch;
	public final workspaceReplacement:WorkspaceReplacement;
	public var replacementPreview(default, null):Null<ReplacementPreview>;
	public var replacementResult(default, null):Null<ReplacementResult>;
	public final settings:SettingsService;
	public final recovery:RecoveryStore;
	public final errors:ErrorLog;
	public final confirmations:ConfirmationService;
	public final documentMatches:Array<SearchMatch> = [];
	public var documentSearchQuery(default, null):String = "";
	var documentMatchIndex:Int = -1;
	var documentSearchDocument:Null<Document>;
	var documentSearchRevision:Int = -1;
	var releaseSettings:Void->Void;
	var appliedSettings:Null<Settings>;
	var lastFileSystemCheck:Float = 0.0;
	var lastConfigurationDiagnostics:String = "";
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
		searchOptions = new SearchOptions();
		workspaceSearch = new WorkspaceSearch(workspace, workspace.jobs, workspaceSearchChanged);
		workspaceReplacement = new WorkspaceReplacement(workspace, new ReplacementBackupStore(ConfigurationPaths.replacementBackup()));
		installSearchCommands();
		plugins = new PluginManager(commands, keymap, context, syntaxes, completions, root.pluginPanels, workspace.jobs, effectiveSettings,
			message -> reportError("plugin", message));
		installPluginCommands();
		installConfigurationCommands();
		installFileCommands();
		commands.add("recovery:open", context -> openRecoveryCommandView());
		releaseSettings = this.settings.subscribe(applySettings);
	}

	public function open(path:String):View
		return root.openDocument(documents.open(path));

	public function openArgument(path:String):Null<View> {
		if (FileSystem.isDirectory(path)) {
			var normalized = workspace.fileSystem.normalize(path);
			var projectSettings = settings.forProject(ConfigurationPaths.projectSettings(normalized));
			var project = workspace.addProject(normalized, projectSettings.current.excludedNames);
			project.setSettings(projectSettings);
			applySettings(projectSettings.current);
			return null;
		}
		return open(path);
	}

	public function add(document:Document):View
		return root.openDocument(documents.add(document));

	public function newDocument():View
		return root.openDocument(documents.createUntitled());

	public function loadPluginManifest(path:String):Bool {
		try {
			return plugins.load(new DynamicPlugin(new PluginManifest(path)));
		} catch (error:Dynamic) {
			reportError("plugin", 'Could not load "$path": ' + Std.string(error));
			return false;
		}
	}

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
		if (context.activeView() == null || context.activeView().getDocument() == null) return;
		root.commandView.open(new CommandViewProvider("Find: ", [], refreshDocumentSearch, function(entry, query, backwards) {
			navigateDocumentMatch(backwards ? -1 : 1);
		}, function() {
			root.setDocumentSearchMatches([]);
		}, navigateDocumentMatch));
	}

	public function openWorkspaceFind():Void {
		root.commandView.open(new CommandViewProvider("Search: ", [], function(query) {
			workspaceSearch.request(query, searchOptions, effectiveSettings().searchMaxResults);
		}, function(entry, query, backwards) {
			if (backwards) root.searchMove(-1);
			root.searchActivate();
			root.commandView.close();
		}, function() {
			workspaceSearch.cancel();
		}, function(delta) {
			root.searchMove(delta);
		}));
	}

	function workspaceSearchChanged():Void {
		root.showSearchResults(workspaceSearch.query, workspaceSearch.results);
		root.searchSidebar.setStatus(workspaceSearch.complete, workspaceSearch.capped, workspaceSearch.errors.length);
	}

	public function previewWorkspaceReplacement(replacement:String):Bool {
		try {
			replacementPreview = workspaceReplacement.preview(workspaceSearch, replacement);
			return true;
		} catch (error:Dynamic) {
			reportError("search", 'Could not preview replacement: ' + Std.string(error));
			return false;
		}
	}

	public function applyWorkspaceReplacement():Bool {
		var preview = replacementPreview;
		if (preview == null) return false;
		try {
			var result = workspaceReplacement.apply(preview);
			replacementResult = result;
			replacementPreview = null;
			reportInformation('Replaced ${result.appliedMatches} matches in ${result.appliedFiles} files; '
				+ '${result.conflicts} conflicts, ${result.failures} failures');
			return result.failures == 0 && result.conflicts == 0;
		} catch (error:Dynamic) {
			reportError("search", 'Could not apply replacement: ' + Std.string(error));
			return false;
		}
	}

	function openWorkspaceReplace():Void {
		root.commandView.open(new CommandViewProvider("Replace in Projects: ", [], function(query) {}, function(entry, replacement, backwards) {
			if (!previewWorkspaceReplacement(replacement)) return;
			var preview = replacementPreview;
			if (preview == null) return;
			confirmations.choose('Preview: ${preview.matchCount} matches in ${preview.files.length} files. Type apply to continue: ', ["apply"],
				function(answer) {
					applyWorkspaceReplacement();
					root.commandView.close();
				}, function() {
					replacementPreview = null;
				});
		}));
	}

	function restoreLastWorkspaceReplacement():Void {
		confirmations.choose("Restore the latest disk replacement backup file by file? Type restore: ", ["restore"], function(answer) {
			var result = workspaceReplacement.restoreLastBackup();
			replacementResult = result;
			reportInformation('Restored ${result.appliedFiles} files; ${result.conflicts} conflicts, ${result.failures} failures');
			root.commandView.close();
		});
	}

	public function replaceCurrent(replacement:String):Bool {
		var document = activeDocument(), match = currentDocumentMatch(), selection = activeSelection();
		if (document == null || match == null || selection == null) return false;
		if (!DocumentSearch.replaceCurrent(document, selection, match, replacement)) return false;
		refreshDocumentSearch(documentSearchQuery);
		return true;
	}

	public function replaceAll(replacement:String):Int {
		var document = activeDocument(), selection = activeSelection();
		if (document == null || selection == null) return 0;
		var count = DocumentSearch.replaceAll(document, selection, documentSearchQuery, replacement, searchOptions);
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
			try {
				for (match in DocumentSearch.find(document, query, searchOptions)) documentMatches.push(match);
			} catch (error:Dynamic) {
				reportError("search", 'Invalid search pattern: ' + Std.string(error));
			}
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
		var document = activeDocument(), match = currentDocumentMatch(), selection = activeSelection();
		if (document != null && match != null && selection != null) {
			if (DocumentSearch.select(document, selection, match)) root.cursorChanged();
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

	function activeSelection():Null<editor.BufferSelection> {
		var current = context.activeView();
		return current == null ? null : current.getSelection();
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
		commands.add("find:toggle-regular-expression", function(context) {
			searchOptions.regularExpression = !searchOptions.regularExpression;
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
		commands.add("workspace:replace", function(context) {
			openWorkspaceReplace();
		}, context -> workspaceSearch.complete && !workspaceSearch.capped && workspaceSearch.results.length > 0);
		commands.add("workspace:restore-last-replacement", function(context) {
			restoreLastWorkspaceReplacement();
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
			var value = settingsFor(context.requireDocument());
			context.requireView().indent(value.tabWidth, value.insertSpaces);
		}, function(context) return context.activeView() != null && context.activeView().getDocument() != null);
		commands.add("doc:unindent", function(context) {
			var value = settingsFor(context.requireDocument());
			context.requireView().unindent(value.tabWidth);
		}, function(context) return context.activeView() != null && context.activeView().getDocument() != null);
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

	function installPluginCommands():Void {
		commands.add("plugins:disable", context -> openPluginAction("Disable Plugin: ", plugins.enabledIds(), plugins.disable),
			context -> plugins.enabledIds().length > 0);
		commands.add("plugins:enable", context -> openPluginAction("Enable Plugin: ", plugins.disabledIds(), plugins.enable),
			context -> plugins.disabledIds().length > 0);
		commands.add("plugins:reload", context -> openPluginAction("Reload Plugin: ", plugins.enabledIds(), plugins.reload),
			context -> plugins.enabledIds().length > 0);
		commands.add("plugins:show-diagnostics", function(context) {
			var entries = [for (diagnostic in plugins.diagnostics()) new CommandViewEntry("Plugin error", diagnostic, diagnostic)];
			root.commandView.open(new CommandViewProvider("Plugin Diagnostics: ", entries, function(query) {}, function(entry, query, backwards) {
				root.commandView.close();
			}));
		});
	}

	function openPluginAction(prompt:String, ids:Array<String>, action:String->Bool):Void {
		var entries = [for (id in ids) new CommandViewEntry(id, "", id)];
		root.commandView.open(new CommandViewProvider(prompt, entries, function(query) {}, function(entry, query, backwards) {
			if (entry != null)
				try {
					if (action(entry.value)) reportInformation(prompt + entry.value);
				} catch (error:Dynamic) {
					reportError("plugin", prompt + entry.value + ": " + Std.string(error));
				}
			root.commandView.close();
		}));
	}

	function settingsFor(document:Document):config.Settings {
		var value = settings.current, matchedLength = -1;
		for (project in workspace.projects)
			if (document.path != null && project.settings != null && StringTools.startsWith(document.path, project.root + "/")
				&& project.root.length > matchedLength) {
				value = project.settings.current;
				matchedLength = project.root.length;
			}
		return value;
	}

	function installFileCommands():Void {
		commands.add("doc:save", function(context) {
			var document = context.requireDocument();
			if (!document.hasBackingPath()) {
				openSaveAs(document);
				return;
			}
			if (!document.save()) {
				reportError("file", 'Save blocked for "' + document.path + '": disk changed or write failed');
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
		commands.add("file:rename", context -> openRenameFile(), context -> selectedFileOperationPath() != null);
		commands.add("file:delete", context -> openDeleteFile(), context -> selectedFileOperationPath() != null);
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
		confirmations.choose('Save changes to "' + document.title + '"? Type save, discard, or cancel: ', ["save", "discard", "cancel"],
			function(answer) {
				if (answer == "cancel") cancelClose();
				else if (answer == "discard") {
						recovery.forget(document);
						closeIndex++;
						continueClose();
				} else if (answer == "save") {
						if (document.hasBackingPath()) {
							if (!document.save()) {
								reportError("file", 'Could not save "' + document.title + '"; close cancelled');
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
			}, cancelClose);
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
				reportError("file", 'Could not save as "$destination"');
				root.commandView.close();
			}
		}));
	}

	public function openCreateFile():Void {
		root.commandView.open(new CommandViewProvider("New File: ", [], function(query) {}, function(entry, path, backwards) {
			var result = fileOperations.createFile(path);
			if (result.success) {
				workspace.refreshProjects();
				if (result.destination != null) open(result.destination);
			} else reportError("file", 'Could not create file "$path": ' + result.detail);
			root.commandView.close();
		}));
	}

	function confirmOverwrite(document:Document):Void {
		confirmations.choose("Disk changed. Type overwrite to save, or Escape to cancel: ", ["overwrite"], function(answer) {
			if (document.save(true)) {
				recovery.forget(document);
				reportInformation("Saved " + document.path);
			} else reportError("file", "Could not save " + document.path);
			root.commandView.close();
		});
	}

	public function openCreateFolder():Void {
		root.commandView.open(new CommandViewProvider("New Folder: ", [], function(query) {}, function(entry, path, backwards) {
			var result = fileOperations.createFolder(path);
			if (!result.success) reportError("file", 'Could not create folder "$path": ' + result.detail);
			workspace.refreshProjects();
			root.commandView.close();
		}));
	}

	public function openRenameFile():Void {
		var source = selectedFileOperationPath();
		if (source == null) return;
		root.commandView.open(new CommandViewProvider("Rename/Move: ", [], function(query) {}, function(entry, destination, backwards) {
			var result = fileOperations.move(source, destination);
			if (!result.success) reportError("file", 'Could not rename "$source": ' + result.detail); else
				for (document in result.documents) root.documentRenamed(document);
			workspace.refreshProjects();
			root.commandView.close();
		}));
	}

	public function openDeleteFile():Void {
		var path = selectedFileOperationPath();
		if (path == null) return;
		confirmations.choose('Type delete to remove "' + path + '": ', ["delete"], function(answer) {
			var result = fileOperations.remove(path);
			if (result.success) {
				for (document in result.documents) root.documentRenamed(document);
				recovery.save(this);
				reportInformation('Moved "$path" to ' + result.destination);
				workspace.refreshProjects();
			} else reportError("file", 'Could not safely delete "$path": ' + result.detail);
			root.commandView.close();
		});
	}

	function selectedFileOperationPath():Null<String> {
		if (!root.searchVisible) {
			var node = root.sidebar.activeNode();
			if (node != null) return node.path;
		}
		var document = activeDocument();
		return document == null || !document.hasBackingPath() ? null : document.requirePath();
	}

	public function openSettingsCommandView():Void {
		var value = effectiveSettings(), entries = [
			new CommandViewEntry("editor.fontPath", value.fontPath, "editor.fontPath"),
			new CommandViewEntry("editor.fontSize", Std.string(value.fontSize), "editor.fontSize"),
			new CommandViewEntry("editor.tabWidth", Std.string(value.tabWidth), "editor.tabWidth"),
			new CommandViewEntry("editor.insertSpaces", Std.string(value.insertSpaces), "editor.insertSpaces"),
			new CommandViewEntry("workbench.sidebarWidth", Std.string(value.sidebarWidth), "workbench.sidebarWidth"),
			new CommandViewEntry("files.exclude", value.excludedNames.join(","), "files.exclude"),
			new CommandViewEntry("search.caseSensitive", Std.string(value.searchCaseSensitive), "search.caseSensitive"),
			new CommandViewEntry("search.wholeWord", Std.string(value.searchWholeWord), "search.wholeWord"),
			new CommandViewEntry("search.maxResults", Std.string(value.searchMaxResults), "search.maxResults"),
			new CommandViewEntry("theme.editorBackground", Std.string(value.editorBackground), "theme.editorBackground"),
			new CommandViewEntry("theme.editorForeground", Std.string(value.editorForeground), "theme.editorForeground"),
			new CommandViewEntry("theme.accent", Std.string(value.accent), "theme.accent"),
			new CommandViewEntry("theme.surface", Std.string(value.surface), "theme.surface"),
			new CommandViewEntry("theme.selection", Std.string(value.selection), "theme.selection"),
			new CommandViewEntry("theme.searchMatch", Std.string(value.searchMatch), "theme.searchMatch"),
			new CommandViewEntry("theme.caret", Std.string(value.caret), "theme.caret")
		];
		for (diagnostic in settings.diagnostics) entries.unshift(new CommandViewEntry("Configuration error", diagnostic, diagnostic));
		var project = workspace.activeProject;
		if (project != null && project.settings != null)
			for (diagnostic in project.settings.diagnostics) entries.unshift(new CommandViewEntry("Configuration error", diagnostic, diagnostic));
		root.commandView.open(new CommandViewProvider("Settings: ", entries, function(query) {}, function(entry, query, backwards) {
			root.commandView.close();
		}));
	}

	public function openKeybindingsCommandView():Void {
		var entries:Array<CommandViewEntry> = [];
		for (binding in effectiveSettings().keybindings)
			entries.push(new CommandViewEntry(keyName(binding.key, binding.modifiers), binding.commands.join(", "), binding.commands[0]));
		root.commandView.open(new CommandViewProvider("Keybindings: ", entries, function(query) {}, function(entry, query, backwards) {
			root.commandView.close();
		}));
	}

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

	function applySettings(value:Settings):Void {
		appliedSettings = value;
		theme.editorBackground = value.editorBackground;
		theme.editorForeground = value.editorForeground;
		theme.accent = value.accent;
		theme.surface = value.surface;
		theme.surfaceElevated = value.surfaceElevated;
		theme.surfaceActive = value.surfaceActive;
		theme.surfaceInactive = value.surfaceInactive;
		theme.surfaceHover = value.surfaceHover;
		theme.border = value.border;
		theme.divider = value.divider;
		theme.foregroundMuted = value.foregroundMuted;
		theme.foregroundSubtle = value.foregroundSubtle;
		theme.foregroundDisabled = value.foregroundDisabled;
		theme.selection = value.selection;
		theme.searchMatch = value.searchMatch;
		theme.caret = value.caret;
		theme.overlay = value.overlay;
		theme.information = value.information;
		theme.warning = value.warning;
		theme.error = value.error;
		theme.scrollbar = value.scrollbar;
		root.status.applySettings(value);
		searchOptions.caseSensitive = value.searchCaseSensitive;
		searchOptions.wholeWord = value.searchWholeWord;
		root.setSidebarWidth(value.sidebarWidth);
		keymap.setConfigured([for (binding in value.keybindings) new KeyBinding(binding.key, binding.modifiers, binding.commands)]);
		if (!root.renderer.reloadFont(value.fontPath, value.fontSize)) {
			var diagnostic = 'could not load font "' + value.fontPath + '"';
			settings.diagnostics.push(diagnostic);
			reportError("configuration", diagnostic);
		}
	}

	function keyName(key:Int, modifiers:Int):String {
		var result = "";
		if (modifiers & Platform.MOD_CTRL != 0) result += "Ctrl+";
		if (modifiers & Platform.MOD_SHIFT != 0) result += "Shift+";
		if (modifiers & Platform.MOD_ALT != 0) result += "Alt+";
		return result + Std.string(key);
	}

	public function update():Void {
		var now = Sys.time();
		settings.reload();
		workspaceSearch.update(now);
		workspace.jobs.update(32);
		if (now - lastFileSystemCheck >= 1.0) {
			lastFileSystemCheck = now;
			documents.checkExternalChanges();
			workspace.refreshProjects();
		}
		var effective = effectiveSettings();
		if (effective != appliedSettings) applySettings(effective);
		reportConfigurationDiagnostics();
		try {
			plugins.update(now);
		} catch (error:Dynamic) {
			reportError("plugin", Std.string(error));
		}
	}

	function effectiveSettings():Settings {
		var document = activeDocument();
		if (document != null) return settingsFor(document);
		var project = workspace.activeProject;
		return project == null || project.settings == null ? settings.current : project.settings.current;
	}

	function reportConfigurationDiagnostics():Void {
		var values = settings.diagnostics.copy();
		for (project in workspace.projects)
			if (project.settings != null)
				for (diagnostic in project.settings.diagnostics) values.push(diagnostic);
		var identity = values.join("\n");
		if (identity == lastConfigurationDiagnostics) return;
		lastConfigurationDiagnostics = identity;
		for (diagnostic in values) reportError("configuration", diagnostic);
	}

	public function reportInformation(message:String):Void
		root.notifications.publish(message, NotificationKind.Information);

	public function reportError(source:String, message:String):Void {
		errors.record(source, message);
		root.notifications.publish(message, NotificationKind.Error);
	}

	public function shutdown():Void {
		releaseSettings();
		plugins.shutdown();
	}
}
