package workspace;

import core.DocumentManager;
import syntax.SyntaxRegistry;

class Workspace {
	public final projects:Array<Project> = [];
	public final documents:DocumentManager;
	public final syntaxes:SyntaxRegistry;
	public final fileSystem:FileSystemService;
	public var activeProject(default, null):Null<Project>;

	public function new(syntaxes:SyntaxRegistry, ?fileSystem:FileSystemService) {
		this.syntaxes = syntaxes;
		this.fileSystem = fileSystem == null ? new FileSystemService() : fileSystem;
		documents = new DocumentManager(syntaxes, this.fileSystem);
	}

	public function addProject(path:String, ?ignoredNames:Array<String>):Project {
		var normalized = fileSystem.normalize(path);
		for (project in projects)
			if (project.root == normalized) {
				activeProject = project;
				return project;
			}
		var project = new Project(normalized, fileSystem, ignoredNames);
		projects.push(project);
		activeProject = project;
		return project;
	}

	public function refreshProjects(directoryBudget:Int = 32):Bool {
		var changed = false;
		for (project in projects) if (project.pollChanges(directoryBudget)) changed = true;
		return changed;
	}
}
