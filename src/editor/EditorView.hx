package editor;

import renderer.Renderer;
import syntax.HighlightToken;
import style.Theme;
import search.SearchMatch;

class EditorView {
	public static inline final HEADER_HEIGHT = 42;
	public static inline final GUTTER_WIDTH = 52;
	public static inline final PADDING = 12;

	public final document:Document;
	public final renderer:Renderer;
	public final theme:Theme;
	public var x(default, null):Int = 0;
	public var y(default, null):Int = 0;
	public var width(default, null):Int;
	public var height(default, null):Int;
	public var scrollX(default, null):Int = 0;
	public var scrollY(default, null):Int = 0;
	public final searchMatches:Array<SearchMatch> = [];
	var mouseSelecting = false;

	public function new(document:Document, renderer:Renderer, theme:Theme, width:Int, height:Int) {
		this.document = document;
		this.renderer = renderer;
		this.theme = theme;
		resize(width, height);
	}

	public function resize(width:Int, height:Int):Void {
		this.width = width;
		this.height = height;
		clampScroll();
	}

	public function setBounds(x:Int, y:Int, width:Int, height:Int):Void {
		this.x = x;
		this.y = y;
		resize(width, height);
	}

	public function moveVertical(delta:Int, extend:Bool):Void {
		document.buffer.moveVertical(delta, extend);
		ensureCaretVisible();
	}

	public function cursorChanged():Void
		ensureCaretVisible();

	public function setSearchMatches(matches:Array<SearchMatch>):Void {
		searchMatches.resize(0);
		for (match in matches) searchMatches.push(match);
	}

	public function wheel(verticalHundredths:Int, horizontalHundredths:Int):Void {
		scrollY -= Std.int(verticalHundredths * renderer.lineHeight * 3 / 100);
		scrollX -= Std.int(horizontalHundredths * renderer.lineHeight * 3 / 100);
		clampScroll();
	}

	public function mouseDown(button:Int, x:Int, y:Int):Void {
		if (button != 1 || !insideText(x, y))
			return;
		document.buffer.setCursor(positionFromPoint(x, y));
		mouseSelecting = true;
		ensureCaretVisible();
	}

	public function mouseMove(x:Int, y:Int):Void {
		if (!mouseSelecting)
			return;
		document.buffer.setCursor(positionFromPoint(x, y), true);
		ensureCaretVisible();
	}

	public function mouseUp(button:Int):Void {
		if (button == 1)
			mouseSelecting = false;
	}

	public function draw(path:String):Void {
		var buffer = document.buffer, lineHeight = renderer.lineHeight, contentTop = y + HEADER_HEIGHT + PADDING,
			contentHeight = height - HEADER_HEIGHT - PADDING, textOffset = GUTTER_WIDTH;
		if (contentHeight < 1) contentHeight = 1;
		if (textOffset >= width) textOffset = width - 1;
		if (textOffset < 0) textOffset = 0;
		var textLeft = x + textOffset;
		renderer.rect(x, y, width, height, 0x181818ff);
		renderer.rect(x, y, width, HEADER_HEIGHT, 0x252525ff);
		renderer.text(x + 12, y + 13, (document.dirty ? "* " : "") + path, 0xccccccff);

		renderer.clip(x, contentTop, width, contentHeight);
		var firstLine = Std.int(scrollY / lineHeight), lastLine = firstLine + Std.int(contentHeight / lineHeight) + 2,
			lineCount = buffer.lineCount();
		if (lastLine > lineCount)
			lastLine = lineCount;
		for (lineIndex in firstLine...lastLine) {
			var y = contentTop + lineIndex * lineHeight - scrollY;
			renderer.text(x + 8, y, Std.string(lineIndex + 1), 0x666666ff);
		}

		renderer.clip(textLeft, contentTop, width - textOffset, contentHeight);
		var selectionStart = buffer.selectionStart(), selectionEnd = buffer.selectionEnd();
		for (lineIndex in firstLine...lastLine) {
			var value = buffer.line(lineIndex),
				y = contentTop + lineIndex * lineHeight - scrollY, x = textLeft - scrollX;
			for (match in searchMatches)
				if (match.line == lineIndex) {
					var matchX = x + renderer.textWidth(value.substr(0, match.column)),
						matchWidth = renderer.textWidth(value.substr(match.column, match.length));
					renderer.rect(matchX, y, matchWidth, lineHeight, 0x613214ff);
				}
			if (selectionEnd.line > lineIndex || selectionEnd.line == lineIndex && selectionEnd.column > 0)
				if (selectionStart.line < lineIndex || selectionStart.line == lineIndex && selectionStart.column <= value.length) {
				var fromColumn = selectionStart.line == lineIndex ? selectionStart.column : 0,
					toColumn = selectionEnd.line == lineIndex ? selectionEnd.column : value.length,
					selectionX = x + renderer.textWidth(value.substr(0, fromColumn)),
					selectionWidth = renderer.textWidth(value.substring(fromColumn, toColumn));
				if (selectionEnd.line > lineIndex)
					selectionWidth += renderer.textWidth(" ");
				renderer.rect(selectionX, y, selectionWidth, lineHeight, 0x264f78ff);
			}
			var highlighted = document.highlighter.line(lineIndex), tokenX = x;
			for (token in highlighted.tokens) {
				var tokenText = value.substr(token.start, token.length);
				renderer.text(tokenX, y, tokenText, theme.tokenColor(token.kind));
				tokenX += renderer.textWidth(tokenText);
			}
		}
		var cursorLine = buffer.cursor.line, cursorValue = buffer.line(cursorLine),
			caretX = textLeft - scrollX + renderer.textWidth(cursorValue.substr(0, buffer.cursor.column)),
			caretY = contentTop + cursorLine * lineHeight - scrollY;
		renderer.rect(caretX, caretY, 2, lineHeight, 0xffffffff);
		renderer.clip(x, y, width, height);
	}

	function ensureCaretVisible():Void {
		var buffer = document.buffer, lineHeight = renderer.lineHeight, viewportHeight = height - HEADER_HEIGHT - PADDING,
			viewportWidth = width - GUTTER_WIDTH, caretY = buffer.cursor.line * lineHeight,
			caretX = renderer.textWidth(buffer.line(buffer.cursor.line).substr(0, buffer.cursor.column)),
			context = lineHeight;
		if (caretY - context < scrollY)
			scrollY = caretY - context;
		else if (caretY + lineHeight + context > scrollY + viewportHeight)
			scrollY = caretY + lineHeight + context - viewportHeight;
		if (caretX < scrollX)
			scrollX = caretX;
		else if (caretX + PADDING > scrollX + viewportWidth)
			scrollX = caretX + PADDING - viewportWidth;
		clampScroll();
	}

	function clampScroll():Void {
		var maxY = document.buffer.lineCount() * renderer.lineHeight - (height - HEADER_HEIGHT - PADDING);
		if (maxY < 0)
			maxY = 0;
		if (scrollY < 0)
			scrollY = 0;
		else if (scrollY > maxY)
			scrollY = maxY;
		if (scrollX < 0)
			scrollX = 0;
	}

	function insideText(x:Int, y:Int):Bool
		return x >= this.x + GUTTER_WIDTH && x < this.x + width
			&& y >= this.y + HEADER_HEIGHT + PADDING && y < this.y + height;

	function positionFromPoint(x:Int, y:Int):BufferPosition {
		var buffer = document.buffer, lineIndex = Std.int((y - this.y - HEADER_HEIGHT - PADDING + scrollY) / renderer.lineHeight);
		if (lineIndex < 0)
			lineIndex = 0;
		else if (lineIndex >= buffer.lineCount())
			lineIndex = buffer.lineCount() - 1;
		var value = buffer.line(lineIndex), targetX = x - this.x - GUTTER_WIDTH + scrollX, column = 0;
		while (column < value.length) {
			var left = renderer.textWidth(value.substr(0, column)), right = renderer.textWidth(value.substr(0, column + 1));
			if (targetX < Std.int((left + right) / 2))
				break;
			column++;
		}
		return buffer.positionAt(lineIndex, column);
	}

}
