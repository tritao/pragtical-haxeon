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
import palette.CommandPalette;
import palette.PaletteEntry;
import platform.Platform;

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
		if (root.palette.active)
			return paletteKeyPressed(key);
		if (key == Platform.KEY_P && modifiers == Platform.MOD_CTRL) {
			openFilePalette();
			return true;
		}
		if (key == Platform.KEY_P && modifiers == Platform.MOD_CTRL + Platform.MOD_SHIFT) {
			openCommandPalette();
			return true;
		}
		var handled = keymap.onKeyPressed(key, modifiers, context);
		if (handled)
			root.cursorChanged();
		return handled;
	}

	public function textInput(text:String):Void {
		if (root.palette.active) root.palette.textInput(text);
		else root.textInput(text);
	}

	public function openFilePalette():Void {
		var entries:Array<PaletteEntry> = [];
		for (project in workspace.projects)
			for (node in project.files()) {
				var relative = node.path.substring(project.root.length + 1);
				entries.push(new PaletteEntry(relative, project.name, node.path));
			}
		root.palette.open(CommandPalette.FILES, entries);
	}

	public function openCommandPalette():Void {
		root.palette.open(CommandPalette.COMMANDS, [for (name in commands.available(context)) new PaletteEntry(name, "", name)]);
	}

	function paletteKeyPressed(key:Int):Bool {
		if (key == Platform.KEY_ESCAPE) root.palette.close();
		else if (key == Platform.KEY_BACKSPACE) root.palette.backspace();
		else if (key == Platform.KEY_UP) root.palette.move(-1);
		else if (key == Platform.KEY_DOWN) root.palette.move(1);
		else if (key == Platform.KEY_ENTER) {
			var mode = root.palette.mode, entry = root.palette.accept();
			if (entry != null)
				if (mode == CommandPalette.FILES) open(entry.value);
				else commands.perform(entry.value, context);
		}
		return true;
	}

	public function update():Void
		plugins.update();

	public function shutdown():Void
		plugins.shutdown();
}
