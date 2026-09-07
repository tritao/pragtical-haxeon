package view;

import core.DocumentManager;
import core.FocusManager;

class LayoutNode {
	public final kind:String;
	public final tabs:TabGroup;
	public var first(default, null):Null<LayoutNode>;
	public var second(default, null):Null<LayoutNode>;
	public var divider(default, null):Float = 0.5;

	public function new(focus:FocusManager, documents:DocumentManager, kind:String = "leaf") {
		this.kind = kind;
		tabs = new TabGroup(focus, documents);
	}

	public function isLeaf():Bool
		return kind == "leaf";
}
