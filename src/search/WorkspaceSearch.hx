package search;

import sys.io.File;
import workspace.Workspace;

class WorkspaceSearch {
	public static function find(workspace:Workspace, query:String, options:SearchOptions, maxResults:Int = 10000):Array<SearchMatch> {
		var result:Array<SearchMatch> = [];
		for (project in workspace.projects)
			for (node in project.files()) {
				var text:Null<String> = null;
				for (document in workspace.documents.documents)
					if (document.path == node.path) text = document.buffer.text;
				if (text == null)
					try text = File.getContent(node.path) catch (error:Dynamic) {}
				if (text != null)
					for (match in DocumentSearch.findText(node.path, text, query, options)) {
						result.push(match);
						if (result.length >= maxResults) return result;
					}
			}
		return result;
	}
}
