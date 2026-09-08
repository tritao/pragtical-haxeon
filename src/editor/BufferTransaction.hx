package editor;

class BufferTransaction {
	public final edits:Array<BufferEdit>;
	public final group:String;
	var finalCursor:Null<BufferPosition>;
	var finalAnchor:Null<BufferPosition>;

	public function new(edit:BufferEdit, group:String) {
		edits = [edit];
		this.group = group;
	}

	public var stateBefore(get, never):Int;
	function get_stateBefore():Int return edits[0].stateBefore;
	public var stateAfter(get, never):Int;
	function get_stateAfter():Int return edits[edits.length - 1].stateAfter;
	public var cursorBefore(get, never):BufferPosition;
	function get_cursorBefore():BufferPosition return edits[0].cursorBefore;
	public var anchorBefore(get, never):BufferPosition;
	function get_anchorBefore():BufferPosition return edits[0].anchorBefore;
	public var cursorAfter(get, never):BufferPosition;
	function get_cursorAfter():BufferPosition return finalCursor == null ? edits[edits.length - 1].cursorAfter : finalCursor;
	public var anchorAfter(get, never):BufferPosition;
	function get_anchorAfter():BufferPosition return finalAnchor == null ? edits[edits.length - 1].anchorAfter : finalAnchor;

	public function setFinalSelection(cursor:BufferPosition, anchor:BufferPosition):Void {
		finalCursor = cursor;
		finalAnchor = anchor;
	}

	public function canAppend(edit:BufferEdit, requestedGroup:String):Bool {
		if (group != "typing" || requestedGroup != group || edit.removed.length != 0 || edit.inserted.indexOf("\n") >= 0) return false;
		var last = edits[edits.length - 1];
		return last.removed.length == 0 && last.inserted.indexOf("\n") < 0
			&& last.cursorAfter.equals(last.anchorAfter) && edit.cursorBefore.equals(edit.anchorBefore)
			&& last.cursorAfter.equals(edit.cursorBefore) && edit.start.equals(edit.cursorBefore);
	}
}
