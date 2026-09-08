package workspace;

import core.DocumentManager;

class FileOperations {
	final workspace:Workspace;
	final documents:DocumentManager;
	final trash:TrashService;

	public function new(workspace:Workspace, trash:TrashService) {
		this.workspace = workspace;
		this.documents = workspace.documents;
		this.trash = trash;
	}

	public function createFile(path:String):FileOperationResult {
		if (path.length == 0 || workspace.fileSystem.exists(path)) return new FileOperationResult(false, "Destination already exists");
		return workspace.fileSystem.createFile(path) ? new FileOperationResult(true, "", workspace.fileSystem.normalize(path))
			: new FileOperationResult(false, "Could not create file");
	}

	public function createFolder(path:String):FileOperationResult {
		if (path.length == 0 || workspace.fileSystem.exists(path)) return new FileOperationResult(false, "Destination already exists");
		return workspace.fileSystem.createFolder(path) ? new FileOperationResult(true, "", workspace.fileSystem.normalize(path))
			: new FileOperationResult(false, "Could not create folder");
	}

	public function move(source:String, destination:String):FileOperationResult {
		if (source.length == 0 || destination.length == 0 || !workspace.fileSystem.exists(source))
			return new FileOperationResult(false, "Source does not exist");
		for (project in workspace.projects)
			if (project.root == source) return new FileOperationResult(false, "Project roots cannot be moved while open");
		var normalized = workspace.fileSystem.normalize(destination);
		if (workspace.fileSystem.exists(normalized)) return new FileOperationResult(false, "Destination already exists");
		if (!workspace.fileSystem.rename(source, normalized)) return new FileOperationResult(false, "Rename or move failed");
		return new FileOperationResult(true, "", normalized, documents.reconcileRename(source, normalized));
	}

	public function remove(path:String):FileOperationResult {
		for (project in workspace.projects)
			if (project.root == path) return new FileOperationResult(false, "Close a project instead of deleting its root");
		var entry = trash.move(path);
		if (entry == null) return new FileOperationResult(false, "Could not move entry to recoverable trash");
		return new FileOperationResult(true, "Moved to recoverable trash", entry.destination, documents.reconcileTrash(path));
	}
}
