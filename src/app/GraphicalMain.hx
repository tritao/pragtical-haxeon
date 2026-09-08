package app;

import platform.Native;
import platform.Platform;
import core.Application;
import renderer.Renderer;
import config.ConfigurationPaths;
import config.SettingsService;
import session.WorkspaceSession;

class GraphicalMain {
	static function main():Int {
		if (Native.abi_version() != Platform.ABI_VERSION)
			throw "platform ABI version mismatch";
		Platform.require(Native.init(false), "initialize graphical platform");
		var arguments = Sys.args();
		var window = Native.window_create("Pragtical Haxeon", 960, 640), running = true;
		Platform.require(window != 0, "create editor window");
		var settings = new SettingsService(ConfigurationPaths.userSettings()), defaults = new config.Settings();
		var renderer = new Renderer(window, defaults.fontPath, defaults.fontSize);
		var application = new Application(renderer, Native.window_width(window), Native.window_height(window), settings);
		var sessionPath = ConfigurationPaths.session(), savedSession = WorkspaceSession.load(sessionPath);
		if (savedSession != null) savedSession.restore(application);
		var documentCount = 0;
		for (argument in arguments) {
			if (StringTools.startsWith(argument, "--plugin="))
				application.loadPluginManifest(argument.substring(9));
			else if (application.openArgument(argument) != null)
				documentCount++;
		}
		if (documentCount == 0 && application.workspace.projects.length == 0)
			application.open("README.md");
		while (running) {
			application.update();
			while (Native.event_poll()) {
				var kind = Native.event_kind();
				if (kind == Platform.EVENT_QUIT)
					running = false;
				else if (kind == Platform.EVENT_TEXT_INPUT) {
					application.textInput(Native.event_text());
				} else if (kind == Platform.EVENT_WINDOW_RESIZED)
					application.root.resize(Native.event_a(), Native.event_b());
				else if (kind == Platform.EVENT_MOUSE_WHEEL)
					application.root.wheel(Native.event_a(), Native.event_b());
				else if (kind == Platform.EVENT_MOUSE_BUTTON_DOWN)
					application.root.mouseDown(Native.event_a(), Native.event_b(), Native.event_c());
				else if (kind == Platform.EVENT_MOUSE_BUTTON_UP)
					application.root.mouseUp(Native.event_a());
				else if (kind == Platform.EVENT_MOUSE_MOVED)
					application.root.mouseMove(Native.event_a(), Native.event_b());
				else if (kind == Platform.EVENT_KEY_DOWN) {
					application.keyPressed(Native.event_a(), Native.event_b());
				}
			}
			renderer.begin();
			application.root.draw();
			renderer.present();
		}
		application.shutdown();
		WorkspaceSession.capture(application).save(sessionPath);
		renderer.destroy();
		Platform.require(Native.window_destroy(window), "destroy editor window");
		Native.shutdown();
		return 0;
	}
}
