package app;

import command.CommandRegistry;
import command.KeyBinding;
import command.Keymap;
import config.SettingsService;
import core.Application;
import platform.Native;
import platform.Platform;
import renderer.Renderer;
import sys.io.File;
import session.WorkspaceSession;
import recovery.RecoverySnapshot;
import recovery.RecoveryStore;

class ConfigurationTestMain {
	static function require(condition:Bool, message:String):Void {
		if (!condition) throw message;
	}

	static function main():Int {
		var arguments = Sys.args(), userPath = arguments[0], projectPath = arguments[1];
		var service = new SettingsService(userPath, projectPath);
		require(service.diagnostics.length == 0, "valid settings produced diagnostics");
		require(service.current.fontSize == 18 && service.current.sidebarWidth == 280 && !service.current.insertSpaces, "layer precedence failed");
		require(service.current.keybindings.length == 1 && service.current.keybindings[0].commands[0] == "doc:redo", "project keybinding did not replace user bindings");
		var lastGood = service.current;
		File.saveContent(projectPath, "version=1\neditor.fontSize=broken\n");
		require(!service.reload() && service.current == lastGood && service.diagnostics.length > 0, "invalid reload replaced last good settings");
		File.saveContent(projectPath, "version=1\neditor.fontSize=19\n");
		require(service.reload() && service.current.fontSize == 19 && service.current.sidebarWidth == 240 && service.current.insertSpaces,
			"fixed reload did not reapply layered settings and defaults");

		Platform.startHeadless();
		var window = Native.window_create("configuration-test", 640, 320), renderer = new Renderer(window, "ignored-headlessly.ttf", 15),
			application = new Application(renderer, 640, 320, service), performed = 0;
		application.commands.add("test:configured", function(context) {
			performed += 1;
		});
		application.keymap.setConfigured([new KeyBinding(Platform.KEY_A, Platform.MOD_CTRL, ["test:configured"])]);
		require(application.keyPressed(Platform.KEY_A, Platform.MOD_CTRL) && performed == 1, "configured binding did not override defaults");
		application.keymap.setConfigured([]);
		require(application.keymap.commandsFor(Platform.KEY_A, Platform.MOD_CTRL)[0] == "doc:select-all", "clearing configured bindings lost defaults");
		application.openArgument(arguments[2]);
		application.open(arguments[3]);
		var sessionPath = arguments[2] + "/state/nested/session.conf", session = WorkspaceSession.capture(application);
		require(session.save(sessionPath), "session did not create its state directory");
		var loaded = WorkspaceSession.load(sessionPath);
		require(loaded != null && loaded.projects.length == 1 && loaded.documents.length == 1 && loaded.activeDocument == arguments[3],
			"session round trip lost workspace state");
		var recoveryPath = arguments[2] + "/state/recovery.conf", recovery = new RecoveryStore(recoveryPath);
		require(recovery.saveSnapshots([new RecoverySnapshot(1, "recovered", arguments[3], "dirty\nrecovered")]), "recovery snapshot save failed");
		var snapshots = recovery.load();
		require(snapshots.length == 1 && snapshots[0].path == arguments[3] && snapshots[0].text == "dirty\nrecovered",
			"length-framed recovery snapshot round trip failed");
		require(recovery.save(application) && recovery.load().length == 1, "unaccepted recovery was erased by periodic save");
		var untitledView = application.newDocument(), untitled = untitledView.getDocument();
		if (untitled == null) throw "untitled view has no document";
		untitledView.textInput("unsaved untitled");
		require(recovery.save(application), "untitled recovery save failed");
		var withUntitled = recovery.load(), untitledSnapshot:Null<RecoverySnapshot> = null;
		for (snapshot in withUntitled) if (snapshot.path == null) untitledSnapshot = snapshot;
		require(untitledSnapshot != null && untitledSnapshot.text == "unsaved untitled", "untitled recovery identity or content was lost");
		var beforeRestore = application.documents.documents.length;
		require(recovery.restore(application, untitledSnapshot) && application.documents.documents.length == beforeRestore + 1,
			"untitled recovery did not create a distinct pathless document");
		var many:Array<RecoverySnapshot> = [];
		for (index in 0...RecoveryStore.MAX_SNAPSHOTS + 5)
			many.push(new RecoverySnapshot(index + 1, "bounded-" + index, null, "value-" + index));
		require(recovery.saveSnapshots(many) && recovery.load().length == RecoveryStore.MAX_SNAPSHOTS
			&& recovery.load()[0].title == "bounded-5", "recovery retention was not bounded to the newest snapshots");
		var accepted = recovery.load()[0];
		require(recovery.forgetSnapshot(accepted) && recovery.load().length == RecoveryStore.MAX_SNAPSHOTS - 1,
			"accepted recovery snapshot was retained");
		require(!recovery.restore(application, new RecoverySnapshot(2, "missing", arguments[2] + "/missing", "lost")) && recovery.diagnostics.length > 0,
			"missing recovery source was silently ignored");
		File.saveContent(recoveryPath, "pragtical-recovery=1\nnope:2:xx");
		require(recovery.load().length == 0 && recovery.diagnostics.length > 0, "corrupt recovery lengths accepted");
		require(!recovery.save(application) && File.getContent(recoveryPath) == "pragtical-recovery=1\nnope:2:xx", "corrupt recovery was overwritten");
		application.shutdown();
		renderer.destroy();
		Platform.require(Native.window_destroy(window), "destroy configuration test window");
		Native.shutdown();
		Sys.println("PASS: typed layered settings, invalid reload rollback, and keybinding overlays");
		return 0;
	}
}
