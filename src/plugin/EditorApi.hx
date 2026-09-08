package plugin;

import command.CommandContext;
import config.Settings;
import jobs.JobHandle;
import jobs.JobScheduler;
import jobs.JobTask;

/** Versioned host capabilities available for the lifetime of one plugin context. */
class EditorApi {
	public static inline final VERSION = 1;
	public final owner:String;
	final editor:CommandContext;
	final panels:PluginPanelRegistry;
	final jobs:JobScheduler;
	final settings:Void->Settings;
	final own:(Void->Void)->Void;

	public function new(owner:String, editor:CommandContext, panels:PluginPanelRegistry, jobs:JobScheduler, settings:Void->Settings,
			own:(Void->Void)->Void) {
		this.owner = owner;
		this.editor = editor;
		this.panels = panels;
		this.jobs = jobs;
		this.settings = settings;
		this.own = own;
	}

	public function activeDocumentText():String
		return editor.requireDocument().buffer.text;

	/** Replaces every active selection as one document transaction. */
	public function replaceSelections(text:String):Bool {
		var view = editor.requireView(), document = editor.requireDocument(), selection = view.getSelection();
		if (selection == null) return false;
		return document.buffer.replaceSelections(selection, [text]);
	}

	public function configuration():Settings
		return settings().copy();

	public function addPanel(id:String, title:String, text:String):PluginPanel {
		var panel = panels.add(owner, id, title, text);
		own(function() {
			panels.remove(panel);
		});
		return panel;
	}

	public function setPanelText(id:String, text:String):Bool {
		var panel = panels.find(owner, id);
		if (panel == null) return false;
		panel.text = text;
		return true;
	}

	/** Observes the active document at registration time until plugin unload. */
	public function onDocumentChanged(listener:PluginDocumentEvent->Void):Void {
		var document = editor.requireDocument(), subscription = document.buffer.subscribe(change -> listener(new PluginDocumentEvent(document, change)));
		own(subscription.release);
	}

	public function schedule(task:JobTask):JobHandle {
		var handle = jobs.schedule(task);
		own(function() {
			jobs.cancel(handle);
		});
		return handle;
	}
}
