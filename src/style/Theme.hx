package style;

import syntax.HighlightToken;

class Theme {
	public var editorBackground:Int = 0x181818ff;
	public var editorForeground:Int = 0xe6e6e6ff;
	public var accent:Int = 0x4f8fccff;

	public function new() {}

	public function tokenColor(kind:Int):Int
		return switch kind {
			case HighlightToken.KEYWORD: 0xc678ddff;
			case HighlightToken.TYPE: 0x56b6c2ff;
			case HighlightToken.NUMBER: 0xd19a66ff;
			case HighlightToken.STRING: 0x98c379ff;
			case HighlightToken.COMMENT: 0x7f848eff;
			case HighlightToken.OPERATOR: 0xabb2bfff;
			case HighlightToken.LITERAL: 0xe06c75ff;
			default: editorForeground;
		};
}
