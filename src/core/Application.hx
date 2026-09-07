package core;

import command.CommandContext;
import command.CommandRegistry;
import command.EditorCommands;
import command.Keymap;
import editor.Document;
import renderer.Renderer;
import view.RootView;
import view.View;

class Application {
	public final documents:DocumentManager;
	public final focus:FocusManager;
	public final root:RootView;
	public final commands:CommandRegistry;
	public final keymap:Keymap;
	public final context:CommandContext;

	public function new(renderer:Renderer, width:Int, height:Int) {
		documents = new DocumentManager();
		focus = new FocusManager();
		root = new RootView(renderer, focus, documents, width, height);
		commands = new CommandRegistry();
		keymap = new Keymap(commands);
		context = new CommandContext(root, focus, documents);
		EditorCommands.install(commands, keymap);
	}

	public function open(path:String):View
		return root.openDocument(documents.open(path));

	public function add(document:Document):View
		return root.openDocument(documents.add(document));

	public function keyPressed(key:Int, modifiers:Int):Bool {
		var handled = keymap.onKeyPressed(key, modifiers, context);
		if (handled)
			root.cursorChanged();
		return handled;
	}
}
