package app;

import platform.Native;
import platform.Platform;
import platform.PlatformEvent;
import core.Application;
import renderer.Renderer;
import config.ConfigurationPaths;
import config.SettingsService;
import session.WorkspaceSession;
import session.SessionPersistence;

class GraphicalMain {
	static var window:Int;
	static var renderer:Renderer;
	static var application:Application;
	static var sessionPersistence:SessionPersistence;
	static var lastRecoverySave:Float;

	static function main():Void {
		if (Native.abi_version() != Platform.ABI_VERSION)
			throw "platform ABI version mismatch";
		var arguments = Sys.args();
		window = Native.window_create("Pragtical Haxeon", 960, 640);
		Platform.require(window != 0, "create editor window");
		var settings = new SettingsService(ConfigurationPaths.userSettings()), defaults = new config.Settings();
		renderer = new Renderer(window, defaults.fontPath, defaults.fontSize);
		application = new Application(renderer, Native.window_width(window), Native.window_height(window), settings);
		var sessionPath = ConfigurationPaths.session(), savedSession = WorkspaceSession.load(sessionPath);
		if (savedSession != null) savedSession.restore(application, application.recovery);
		sessionPersistence = new SessionPersistence(sessionPath);
		sessionPersistence.begin(application);
		lastRecoverySave = Sys.time();
		var documentCount = 0;
		for (argument in arguments) {
			if (StringTools.startsWith(argument, "--plugin="))
				application.loadPluginManifest(argument.substring(9));
			else if (application.openArgument(argument) != null)
				documentCount++;
		}
		if (documentCount == 0 && application.workspace.projects.length == 0)
			application.newDocument();
		application.openRecoveryCommandView();
		Native.host_install(onEvent, iterate, quit);
	}

	static function onEvent():Void {
		var event = Platform.pollEvent();
		while (event != null) {
			switch event {
				case Quit: application.requestQuit();
				case TextInput(_, text): application.textInput(text);
				case WindowResize(_, width, height): application.root.resize(width, height);
				case DisplayScaleChanged(_, scaleMilli): application.root.displayScaleChanged(scaleMilli);
				case MouseWheel(_, vertical, horizontal): application.root.wheel(vertical, horizontal);
				case MouseButtonDown(_, button, x, y, clicks): application.root.mouseDown(button, x, y, clicks);
				case MouseButtonUp(_, button, _, _, _): application.root.mouseUp(button);
				case MouseMove(_, x, y, _, _): application.root.mouseMove(x, y);
				case KeyDown(_, key, modifiers): application.keyPressed(key, modifiers);
				case KeyUp(_, _, _):
				default:
			}
			event = Platform.pollEvent();
		}
	}

	static function iterate():Int {
		application.update();
		sessionPersistence.update(application, Sys.time());
		if (Sys.time() - lastRecoverySave >= 2.0) {
			application.recovery.save(application);
			lastRecoverySave = Sys.time();
		}
		renderer.begin();
		application.root.draw();
		renderer.present();
		return application.quitReady ? 0 : 1;
	}

	static function quit():Void {
		application.shutdown();
		application.recovery.save(application);
		sessionPersistence.flush(application);
		renderer.destroy();
		Platform.require(Native.window_destroy(window), "destroy editor window");
	}
}
