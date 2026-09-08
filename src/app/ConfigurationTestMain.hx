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

class ConfigurationTestMain {
	static function require(condition:Bool, message:String):Void {
		if (!condition) throw message;
	}

	static function main():Int {
		var arguments = Sys.args(), userPath = arguments[0], projectPath = arguments[1];
		var service = new SettingsService(userPath, projectPath);
		require(service.diagnostics.length == 0, "valid settings produced diagnostics");
		require(service.current.fontSize == 18 && service.current.sidebarWidth == 280, "layer precedence failed");
		require(service.current.keybindings.length == 1 && service.current.keybindings[0].commands[0] == "doc:redo", "project keybinding did not replace user bindings");
		var lastGood = service.current;
		File.saveContent(projectPath, "version=1\neditor.fontSize=broken\n");
		require(!service.reload() && service.current == lastGood && service.diagnostics.length > 0, "invalid reload replaced last good settings");
		File.saveContent(projectPath, "version=1\neditor.fontSize=19\n");
		require(service.reload() && service.current.fontSize == 19 && service.current.sidebarWidth == 240, "fixed reload did not reapply layered settings");

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
		application.shutdown();
		renderer.destroy();
		Platform.require(Native.window_destroy(window), "destroy configuration test window");
		Native.shutdown();
		Sys.println("PASS: typed layered settings, invalid reload rollback, and keybinding overlays");
		return 0;
	}
}
