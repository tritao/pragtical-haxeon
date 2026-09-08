package search;

import editor.BufferPosition;
import editor.BufferSelection;
import workspace.Workspace;

class WorkspaceReplacement {
	final workspace:Workspace;
	final backups:ReplacementBackupStore;

	public function new(workspace:Workspace, backups:ReplacementBackupStore) {
		this.workspace = workspace;
		this.backups = backups;
	}

	public function preview(search:WorkspaceSearch, replacement:String):ReplacementPreview {
		if (!search.complete) throw "Search is still running";
		if (search.capped) throw "Search result cap must be raised before replacement";
		var grouped:Map<String, Array<SearchMatch>> = [];
		for (match in search.results) {
			var matches = grouped.get(match.path);
			if (matches == null) {
				matches = [];
				grouped.set(match.path, matches);
			}
			matches.push(match);
		}
		var paths = [for (path in grouped.keys()) path];
		paths.sort(Reflect.compare);
		var files:Array<ReplacementFilePreview> = [], total = 0;
		for (path in paths) {
			var matches = grouped.get(path);
			if (matches == null || matches.length == 0) continue;
			var document = matches[0].document;
			var original = document == null ? workspace.fileSystem.read(path) : document.buffer.text;
			for (match in matches)
				if (document != null ? !DocumentSearch.valid(document, match) : textAt(original, match) != match.matchedText)
					throw 'Search result changed before preview: "$path"';
			var proposed = applyMatches(original, matches, replacement);
			files.push(new ReplacementFilePreview(path, original, proposed, matches.length, document,
				document == null ? -1 : document.buffer.stateId));
			total += matches.length;
		}
		return new ReplacementPreview(search.generation, search.query, replacement, files, total);
	}

	public function apply(preview:ReplacementPreview):ReplacementResult {
		if (preview.applied) throw "Replacement preview was already applied";
		preview.markApplied();
		var ready:Array<ReplacementFilePreview> = [], outcomes:Array<ReplacementOutcome> = [], diskBackups:Array<ReplacementBackup> = [];
		for (file in preview.files) {
			var current:Null<String> = null;
			try current = file.document == null ? workspace.fileSystem.read(file.path) : file.document.buffer.text catch (error:Dynamic) {
				outcomes.push(new ReplacementOutcome(file.path, ReplacementOutcome.FAILED, file.matchCount, Std.string(error)));
			}
			if (current != null) {
				var revisionMatches = file.document == null || file.document.buffer.stateId == file.revision;
				if (!revisionMatches || current != file.originalText)
					outcomes.push(new ReplacementOutcome(file.path, ReplacementOutcome.CONFLICT, file.matchCount, "Content changed after preview"));
				else {
					ready.push(file);
					if (file.document == null) diskBackups.push(new ReplacementBackup(file.path, current, file.proposedText, file.matchCount));
				}
			}
		}
		if (diskBackups.length > 0 && !backups.save(diskBackups)) {
			for (file in ready)
				outcomes.push(new ReplacementOutcome(file.path, ReplacementOutcome.FAILED, file.matchCount,
					"Could not retain the pre-replacement disk backup"));
			return new ReplacementResult(outcomes);
		}
		for (file in ready)
			if (file.document != null) {
				var selection = new BufferSelection();
				if (file.document.buffer.replaceAllText(file.proposedText, selection))
					outcomes.push(new ReplacementOutcome(file.path, ReplacementOutcome.APPLIED, file.matchCount));
				else outcomes.push(new ReplacementOutcome(file.path, ReplacementOutcome.FAILED, file.matchCount, "Document edit failed"));
			} else if (workspace.fileSystem.writeAtomic(file.path, file.proposedText))
				outcomes.push(new ReplacementOutcome(file.path, ReplacementOutcome.APPLIED, file.matchCount));
			else outcomes.push(new ReplacementOutcome(file.path, ReplacementOutcome.FAILED, file.matchCount, "Atomic write failed"));
		return new ReplacementResult(outcomes);
	}

	/** Best-effort per-file recovery of the latest disk batch; changed files are conflicts, never overwritten. */
	public function restoreLastBackup():ReplacementResult {
		var outcomes:Array<ReplacementOutcome> = [], files:Array<ReplacementBackup>;
		try files = backups.load() catch (error:Dynamic) {
			return new ReplacementResult([new ReplacementOutcome(backups.path, ReplacementOutcome.FAILED, 0, Std.string(error))]);
		}
		for (file in files) {
			var current:Null<String> = null;
			try current = workspace.fileSystem.read(file.path) catch (error:Dynamic) {
				outcomes.push(new ReplacementOutcome(file.path, ReplacementOutcome.FAILED, file.matchCount, Std.string(error)));
			}
			if (current != null)
				if (current != file.expectedCurrent)
					outcomes.push(new ReplacementOutcome(file.path, ReplacementOutcome.CONFLICT, file.matchCount,
						"Content changed after replacement"));
				else if (workspace.fileSystem.writeAtomic(file.path, file.text))
					outcomes.push(new ReplacementOutcome(file.path, ReplacementOutcome.APPLIED, file.matchCount));
				else outcomes.push(new ReplacementOutcome(file.path, ReplacementOutcome.FAILED, file.matchCount, "Atomic restore failed"));
		}
		return new ReplacementResult(outcomes);
	}

	static function applyMatches(text:String, matches:Array<SearchMatch>, replacement:String):String {
		var ordered = matches.copy();
		ordered.sort(function(left, right) return offsetOf(text, right.line, right.column) - offsetOf(text, left.line, left.column));
		var result = text;
		for (match in ordered) {
			var offset = offsetOf(text, match.line, match.column);
			result = result.substring(0, offset) + DocumentSearch.replacementFor(match, replacement) + result.substring(offset + match.length);
		}
		return result;
	}

	static function textAt(text:String, match:SearchMatch):String {
		var offset = offsetOf(text, match.line, match.column);
		return text.substr(offset, match.length);
	}

	static function offsetOf(text:String, line:Int, column:Int):Int {
		var offset = 0, current = 0;
		while (current < line) {
			var newline = text.indexOf("\n", offset);
			if (newline < 0) return text.length;
			offset = newline + 1;
			current++;
		}
		return offset + column;
	}
}
