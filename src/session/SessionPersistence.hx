package session;

import core.Application;

/** Debounces session snapshots and supports an explicit shutdown flush. */
class SessionPersistence {
	public static inline final CHECK_INTERVAL_SECONDS = 0.25;
	public static inline final DEBOUNCE_SECONDS = 0.75;
	final path:String;
	var lastChecked:Float = -1.0;
	var changedAt:Float = -1.0;
	var observed:String = "";
	var saved:String = "";

	public function new(path:String) this.path = path;

	public function begin(application:Application):Void {
		observed = WorkspaceSession.capture(application).encode();
		saved = observed;
		changedAt = -1.0;
	}

	public function update(application:Application, now:Float):Bool {
		if (lastChecked >= 0 && now - lastChecked < CHECK_INTERVAL_SECONDS) return false;
		lastChecked = now;
		var current = WorkspaceSession.capture(application).encode();
		if (current != observed) {
			observed = current;
			changedAt = now;
			return false;
		}
		if (changedAt < 0 || now - changedAt < DEBOUNCE_SECONDS || current == saved) return false;
		if (!WorkspaceSession.capture(application).save(path)) return false;
		saved = current;
		changedAt = -1.0;
		return true;
	}

	public function flush(application:Application):Bool {
		var session = WorkspaceSession.capture(application), current = session.encode();
		if (current == saved) return true;
		if (!session.save(path)) return false;
		observed = current;
		saved = current;
		changedAt = -1.0;
		return true;
	}
}
