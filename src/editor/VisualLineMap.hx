package editor;

/** Maps stable document positions to wrapped rows while folds hide whole lines. */
class VisualLineMap {
	public final buffer:TextBuffer;
	public var wrapColumns(default, null):Int;
	final rows:Array<VisualLine> = [];
	final folds:Array<FoldRegion> = [];

	public function new(buffer:TextBuffer, wrapColumns:Int = 0) {
		this.buffer = buffer;
		this.wrapColumns = wrapColumns;
		rebuild();
	}

	public function setWrapColumns(value:Int):Void {
		if (value < 0) value = 0;
		if (value == wrapColumns) return;
		wrapColumns = value;
		rebuild();
	}

	public function lines():Array<VisualLine>
		return rows.copy();

	public function rowCount():Int
		return rows.length;

	public function lineAt(row:Int):VisualLine {
		if (row < 0) row = 0;
		if (row >= rows.length) row = rows.length - 1;
		return rows[row];
	}

	public function rowAt(position:BufferPosition):Int {
		for (index in 0...rows.length) {
			var row = rows[index];
			if (row.foldedThroughLine >= 0 && position.line > row.documentLine && position.line <= row.foldedThroughLine) return index;
			if (row.documentLine == position.line && position.column >= row.startColumn
				&& (position.column < row.endColumn || position.column == row.endColumn && isLastSegment(index))) return index;
		}
		return rows.length - 1;
	}

	public function positionAt(row:Int, visualColumn:Int):BufferPosition {
		var line = lineAt(row), column = line.startColumn + visualColumn;
		if (column < line.startColumn) column = line.startColumn;
		if (column > line.endColumn) column = line.endColumn;
		return buffer.positionAt(line.documentLine, column);
	}

	public function moveVertical(position:BufferPosition, delta:Int, preferredVisualColumn:Int = -1):BufferPosition {
		var sourceRow = rowAt(position), source = lineAt(sourceRow), column = preferredVisualColumn < 0 ? position.column - source.startColumn : preferredVisualColumn,
			target = sourceRow + delta;
		if (target < 0) target = 0;
		if (target >= rows.length) target = rows.length - 1;
		return positionAt(target, column);
	}

	public function toggleFold(startLine:Int, endLine:Int):Bool {
		for (index in 0...folds.length)
			if (folds[index].startLine == startLine) {
				folds.splice(index, 1);
				rebuild();
				return false;
			}
		if (startLine < 0 || startLine >= buffer.lineCount() - 1) return false;
		if (endLine >= buffer.lineCount()) endLine = buffer.lineCount() - 1;
		folds.push(new FoldRegion(startLine, endLine));
		folds.sort(function(left, right) return left.startLine - right.startLine);
		rebuild();
		return true;
	}

	/** Expands a fold before a caret, selection or search target enters it. */
	public function reveal(position:BufferPosition):Bool {
		var changed = false, index = folds.length;
		while (index > 0) {
			index--;
			if (folds[index].contains(position.line)) {
				folds.splice(index, 1);
				changed = true;
			}
		}
		if (changed) rebuild();
		return changed;
	}

	public function rebuild():Void {
		rows.resize(0);
		var line = 0;
		while (line < buffer.lineCount()) {
			var text = buffer.line(line), fold = foldAt(line), width = wrapColumns <= 0 ? (text.length > 0 ? text.length : 1) : wrapColumns,
				column = 0;
			if (text.length == 0) rows.push(new VisualLine(line, 0, 0, fold == null ? -1 : fold.endLine));
			while (column < text.length) {
				var end = column + width;
				if (end > text.length) end = text.length;
				end = buffer.positionAt(line, end).column;
				if (end <= column) end = buffer.positionAt(line, column + 1).column;
				rows.push(new VisualLine(line, column, end, fold != null && end == text.length ? fold.endLine : -1));
				column = end;
			}
			line = fold == null ? line + 1 : fold.endLine + 1;
		}
	}

	function foldAt(line:Int):Null<FoldRegion> {
		for (fold in folds) if (fold.startLine == line) return fold;
		return null;
	}

	function isLastSegment(index:Int):Bool
		return index + 1 == rows.length || rows[index + 1].documentLine != rows[index].documentLine;
}
