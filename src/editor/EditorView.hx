package editor;

import renderer.Renderer;
import syntax.HighlightToken;
import style.Theme;
import search.SearchMatch;

class EditorView {
	public static inline final HEADER_HEIGHT = 42;
	public static inline final GUTTER_WIDTH = 52;
	public static inline final PADDING = 12;
	public static inline final SCROLLBAR_SIZE = 8;

	public final document:Document;
	public final renderer:Renderer;
	public final theme:Theme;
	public final selection:BufferSelection;
	final clock:EditorClock;
	public var x(default, null):Int = 0;
	public var y(default, null):Int = 0;
	public var width(default, null):Int;
	public var height(default, null):Int;
	public var scrollX(default, null):Int = 0;
	public var scrollY(default, null):Int = 0;
	public final searchMatches:Array<SearchMatch> = [];
	var mouseSelecting = false;
	var dragMouseX:Int = 0;
	var dragMouseY:Int = 0;
	var lastDragScroll:Float = -1.0;
	var draggingVerticalScrollbar:Bool = false;
	var draggingHorizontalScrollbar:Bool = false;

	public function new(document:Document, renderer:Renderer, theme:Theme, width:Int, height:Int, ?selection:BufferSelection, ?clock:EditorClock) {
		this.document = document;
		this.renderer = renderer;
		this.theme = theme;
		this.selection = selection == null ? new BufferSelection() : selection;
		this.clock = clock == null ? new SystemEditorClock() : clock;
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
		selection.moveVertical(document.buffer, delta, extend);
		ensureCaretVisible();
	}

	public function movePage(delta:Int, extend:Bool):Void {
		var lines = Std.int((height - HEADER_HEIGHT - PADDING) / renderer.lineHeight);
		if (lines < 1) lines = 1;
		selection.moveVertical(document.buffer, delta * lines, extend);
		ensureCaretVisible();
	}

	public function cursorChanged():Void
		ensureCaretVisible();

	public function restoreScroll(x:Int, y:Int):Void {
		scrollX = x;
		scrollY = y;
		clampScroll();
	}

	public function setSearchMatches(matches:Array<SearchMatch>):Void {
		searchMatches.resize(0);
		for (match in matches) searchMatches.push(match);
	}

	public function wheel(verticalHundredths:Int, horizontalHundredths:Int):Void {
		scrollY -= Std.int(verticalHundredths * renderer.lineHeight * 3 / 100);
		scrollX -= Std.int(horizontalHundredths * renderer.lineHeight * 3 / 100);
		clampScroll();
	}

	public function mouseDown(button:Int, x:Int, y:Int, clicks:Int = 1):Void {
		if (button != 1) return;
		if (x >= this.x + width - SCROLLBAR_SIZE && y >= this.y + HEADER_HEIGHT + PADDING && y < this.y + height - SCROLLBAR_SIZE) {
			draggingVerticalScrollbar = true;
			updateVerticalScrollbar(y);
			return;
		}
		if (y >= this.y + height - SCROLLBAR_SIZE && x >= this.x + GUTTER_WIDTH && x < this.x + width - SCROLLBAR_SIZE) {
			draggingHorizontalScrollbar = true;
			updateHorizontalScrollbar(x);
			return;
		}
		if (!insideText(x, y)) return;
		var position = positionFromPoint(x, y), buffer = document.buffer;
		if (clicks >= 3) {
			var from = new BufferPosition(position.line, 0), to = position.line + 1 < buffer.lineCount()
				? new BufferPosition(position.line + 1, 0) : new BufferPosition(position.line, buffer.line(position.line).length);
			selection.restore(buffer, to, from);
		} else if (clicks == 2)
			selection.restore(buffer, buffer.wordEndAt(position), buffer.wordStartAt(position));
		else selection.setCursor(buffer, position);
		mouseSelecting = true;
		dragMouseX = x;
		dragMouseY = y;
		lastDragScroll = -1.0;
		ensureCaretVisible();
	}

	public function mouseMove(x:Int, y:Int):Void {
		if (draggingVerticalScrollbar) { updateVerticalScrollbar(y); return; }
		if (draggingHorizontalScrollbar) { updateHorizontalScrollbar(x); return; }
		if (!mouseSelecting)
			return;
		dragMouseX = x;
		dragMouseY = y;
		selection.setCursor(document.buffer, positionFromPoint(x, y), true);
		updateDragAutoscroll();
		ensureCaretVisible();
	}

	public function mouseUp(button:Int):Void {
		if (button == 1) {
			mouseSelecting = false;
			draggingVerticalScrollbar = false;
			draggingHorizontalScrollbar = false;
		}
	}

	public function draw(path:String):Void {
		updateDragAutoscroll();
		var buffer = document.buffer, lineHeight = renderer.lineHeight, contentTop = y + HEADER_HEIGHT + PADDING,
			contentHeight = height - HEADER_HEIGHT - PADDING - SCROLLBAR_SIZE, textOffset = GUTTER_WIDTH;
		if (contentHeight < 1) contentHeight = 1;
		if (textOffset >= width) textOffset = width - 1;
		if (textOffset < 0) textOffset = 0;
		var textLeft = x + textOffset;
		var bracketPair = document.matchingBrackets(selection.cursor);
		renderer.rect(x, y, width, height, theme.editorBackground);
		renderer.rect(x, y, width, HEADER_HEIGHT, theme.surfaceElevated);
		renderer.text(x + 12, y + 13, (document.dirty ? "* " : "") + path, theme.foregroundMuted);

		renderer.clip(x, contentTop, width, contentHeight);
		var firstLine = Std.int(scrollY / lineHeight), lastLine = firstLine + Std.int(contentHeight / lineHeight) + 2,
			lineCount = buffer.lineCount();
		if (lastLine > lineCount)
			lastLine = lineCount;
		for (lineIndex in firstLine...lastLine) {
			var y = contentTop + lineIndex * lineHeight - scrollY;
			renderer.text(x + 8, y, Std.string(lineIndex + 1), theme.foregroundDisabled);
		}

		renderer.clip(textLeft, contentTop, width - textOffset - SCROLLBAR_SIZE, contentHeight);
		for (lineIndex in firstLine...lastLine) {
			var value = buffer.line(lineIndex),
				y = contentTop + lineIndex * lineHeight - scrollY, x = textLeft - scrollX;
			if (bracketPair != null) {
				drawBracketBackground(bracketPair.first, lineIndex, value, x, y, lineHeight);
				drawBracketBackground(bracketPair.second, lineIndex, value, x, y, lineHeight);
			}
			for (match in searchMatches)
				if (match.line == lineIndex) {
					var matchX = x + renderer.textWidth(value.substr(0, match.column)),
						matchWidth = renderer.textWidth(value.substr(match.column, match.length));
					renderer.rect(matchX, y, matchWidth, lineHeight, theme.searchMatch);
				}
			for (range in selection.allRanges()) {
				var selectionStart = range.start(), selectionEnd = range.end();
				if (selectionEnd.line > lineIndex || selectionEnd.line == lineIndex && selectionEnd.column > 0)
					if (selectionStart.line < lineIndex || selectionStart.line == lineIndex && selectionStart.column <= value.length) {
						var fromColumn = selectionStart.line == lineIndex ? selectionStart.column : 0,
							toColumn = selectionEnd.line == lineIndex ? selectionEnd.column : value.length,
							selectionX = x + renderer.textWidth(value.substr(0, fromColumn)),
							selectionWidth = renderer.textWidth(value.substring(fromColumn, toColumn));
						if (selectionEnd.line > lineIndex) selectionWidth += renderer.textWidth(" ");
						renderer.rect(selectionX, y, selectionWidth, lineHeight, theme.selection);
					}
			}
			var highlighted = document.highlighter.line(lineIndex), tokenX = x;
			for (token in highlighted.tokens) {
				var tokenText = value.substr(token.start, token.length);
				renderer.text(tokenX, y, tokenText, theme.tokenColor(token.kind));
				tokenX += renderer.textWidth(tokenText);
			}
		}
		for (range in selection.allRanges()) {
			var cursorLine = range.cursor.line, cursorValue = buffer.line(cursorLine),
				caretX = textLeft - scrollX + renderer.textWidth(cursorValue.substr(0, range.cursor.column)),
				caretY = contentTop + cursorLine * lineHeight - scrollY;
			renderer.rect(caretX, caretY, 2, lineHeight, theme.caret);
		}
		drawScrollbars(contentTop, contentHeight);
		renderer.clip(x, y, width, height);
	}

	function drawBracketBackground(position:BufferPosition, line:Int, value:String, x:Int, y:Int, lineHeight:Int):Void {
		if (position.line != line) return;
		var left = x + renderer.textWidth(value.substr(0, position.column)), width = renderer.textWidth(value.substr(position.column, 1));
		renderer.rect(left, y, width, lineHeight, theme.searchMatch);
	}

	function drawScrollbars(contentTop:Int, contentHeight:Int):Void {
		var totalHeight = document.buffer.lineCount() * renderer.lineHeight,
			viewportWidth = width - GUTTER_WIDTH - SCROLLBAR_SIZE, maximumWidth = maximumLineWidth();
		renderer.clip(x, y, width, height);
		if (totalHeight > contentHeight && contentHeight > 0) {
			var thumbHeight = Std.int(contentHeight * contentHeight / totalHeight);
			if (thumbHeight < 20) thumbHeight = 20;
			var maxScroll = totalHeight - contentHeight, thumbY = contentTop + Std.int((contentHeight - thumbHeight) * scrollY / maxScroll);
			renderer.rect(x + width - SCROLLBAR_SIZE, contentTop, SCROLLBAR_SIZE, contentHeight, theme.editorBackground);
			renderer.rect(x + width - SCROLLBAR_SIZE + 2, thumbY, SCROLLBAR_SIZE - 3, thumbHeight, theme.scrollbar);
		}
		if (maximumWidth > viewportWidth && viewportWidth > 0) {
			var thumbWidth = Std.int(viewportWidth * viewportWidth / maximumWidth);
			if (thumbWidth < 20) thumbWidth = 20;
			var maxScroll = maximumWidth - viewportWidth, thumbX = x + GUTTER_WIDTH + Std.int((viewportWidth - thumbWidth) * scrollX / maxScroll);
			renderer.rect(x + GUTTER_WIDTH, y + height - SCROLLBAR_SIZE, viewportWidth, SCROLLBAR_SIZE, theme.editorBackground);
			renderer.rect(thumbX, y + height - SCROLLBAR_SIZE + 2, thumbWidth, SCROLLBAR_SIZE - 3, theme.scrollbar);
		}
	}

	function updateDragAutoscroll():Void {
		if (!mouseSelecting) return;
		var top = y + HEADER_HEIGHT + PADDING, bottom = y + height, direction = 0;
		if (dragMouseY < top) direction = -1 - Std.int((top - dragMouseY) / renderer.lineHeight);
		else if (dragMouseY >= bottom) direction = 1 + Std.int((dragMouseY - bottom) / renderer.lineHeight);
		if (direction == 0) return;
		var now = clock.now();
		if (lastDragScroll >= 0 && now - lastDragScroll < 0.05) return;
		lastDragScroll = now;
		scrollY += direction * renderer.lineHeight;
		clampScroll();
		var targetY = direction < 0 ? top : bottom - 1;
		selection.setCursor(document.buffer, positionFromPoint(dragMouseX, targetY), true);
	}

	function ensureCaretVisible():Void {
		var buffer = document.buffer, lineHeight = renderer.lineHeight, viewportHeight = height - HEADER_HEIGHT - PADDING - SCROLLBAR_SIZE,
			viewportWidth = width - GUTTER_WIDTH - SCROLLBAR_SIZE, caretY = selection.cursor.line * lineHeight,
			caretX = renderer.textWidth(buffer.line(selection.cursor.line).substr(0, selection.cursor.column)),
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
		var maxY = document.buffer.lineCount() * renderer.lineHeight - (height - HEADER_HEIGHT - PADDING - SCROLLBAR_SIZE);
		if (maxY < 0)
			maxY = 0;
		if (scrollY < 0)
			scrollY = 0;
		else if (scrollY > maxY)
			scrollY = maxY;
		if (scrollX < 0)
			scrollX = 0;
		var maxX = maximumLineWidth() - (width - GUTTER_WIDTH - SCROLLBAR_SIZE);
		if (maxX < 0) maxX = 0;
		if (scrollX > maxX) scrollX = maxX;
	}

	function maximumLineWidth():Int {
		var result = 0;
		for (line in 0...document.buffer.lineCount()) {
			var width = renderer.textWidth(document.buffer.line(line));
			if (width > result) result = width;
		}
		return result;
	}

	function updateVerticalScrollbar(pointerY:Int):Void {
		var viewport = height - HEADER_HEIGHT - PADDING - SCROLLBAR_SIZE, maximum = document.buffer.lineCount() * renderer.lineHeight - viewport;
		if (maximum <= 0 || viewport <= 0) { scrollY = 0; return; }
		var position = pointerY - y - HEADER_HEIGHT - PADDING;
		if (position < 0) position = 0;
		if (position > viewport) position = viewport;
		scrollY = Std.int(position * maximum / viewport);
		clampScroll();
	}

	function updateHorizontalScrollbar(pointerX:Int):Void {
		var viewport = width - GUTTER_WIDTH - SCROLLBAR_SIZE, maximum = maximumLineWidth() - viewport;
		if (maximum <= 0 || viewport <= 0) { scrollX = 0; return; }
		var position = pointerX - x - GUTTER_WIDTH;
		if (position < 0) position = 0;
		if (position > viewport) position = viewport;
		scrollX = Std.int(position * maximum / viewport);
		clampScroll();
	}

	function insideText(x:Int, y:Int):Bool
		return x >= this.x + GUTTER_WIDTH && x < this.x + width - SCROLLBAR_SIZE
			&& y >= this.y + HEADER_HEIGHT + PADDING && y < this.y + height - SCROLLBAR_SIZE;

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
