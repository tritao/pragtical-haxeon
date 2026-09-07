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

class Application {
	public final documents:DocumentManager;
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
		documents = new DocumentManager(syntaxes);
		focus = new FocusManager();
		root = new RootView(renderer, theme, focus, documents, width, height);
		commands = new CommandRegistry();
		keymap = new Keymap(commands);
		context = new CommandContext(root, focus, documents);
		EditorCommands.install(commands, keymap);
		plugins = new PluginManager(commands, keymap, context, syntaxes);
	}

	public function open(path:String):View
		return root.openDocument(documents.open(path));

	public function add(document:Document):View
		return root.openDocument(documents.add(document));

	public function loadPluginManifest(path:String):Bool
		return plugins.load(new DynamicPlugin(new PluginManifest(path)));

	public function keyPressed(key:Int, modifiers:Int):Bool {
		var handled = keymap.onKeyPressed(key, modifiers, context);
		if (handled)
			root.cursorChanged();
		return handled;
	}

	public function update():Void
		plugins.update();

	public function shutdown():Void
		plugins.shutdown();
}
