import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Highlight
{
	int row = 0;
	int column = 0;
	int howManyLines = 0;

	Highlight(this.row, this.column, this.howManyLines);

	Highlight.copyWithLines(Highlight other, int linesNumber) : 
		row = other.row,
		column = other.column,
		howManyLines = linesNumber;

	@override
	bool operator ==(dynamic other)
	{
		if (identical(this, other))
			return true;
		if (other is! Highlight)
			return false;
		final Highlight typedOther = other;
		return (typedOther.howManyLines == this.howManyLines) && (typedOther.row == this.row) && (typedOther.column == this.column);
	}

	@override
	int get hashCode 
	{
		return hashValues(howManyLines, row, column);
	}
}

class TextRenderObject extends RenderBox
{
	static const double FONT_SIZE = 16.0;
	static const String FONT_FAMILY = "Inconsolata";
	static const FontWeight FONT_WEIGHT = FontWeight.w100;
	static const double LINE_HEIGHT_MULTIPLIER = 18.0/16.0;
	static const double LINES_NUM_WIDTH = 60.0;
	static const int LINES_RECT_PADDING = 15;
	static const int CODE_PADDING_LEFT = 15;
	static const int CODE_PADDING_TOP = 10;
	static const int HIGHLIGHT_PADDING = 1;

	String _text;
	TextStyle style;
	Highlight _highlight;
	int _highlightAlpha;
	int _maxLines;
	double _lineScrollOffset;
	double _glyphHeight = 10.0;
	double _glyphWidth = 10.0;

	ui.Paragraph _codeParagraph;
	ui.Paragraph _linesParagraph;

	TextRenderObject() : 
		this._lineScrollOffset = 0.0,
		this._highlight = new Highlight(-1, 0, 0),
		this._highlightAlpha = 56
	{
		// Initialize the Line Height for this style
		ui.ParagraphStyle codeStyle = new ui.ParagraphStyle(
				fontFamily: FONT_FAMILY,
				fontSize: FONT_SIZE,
				lineHeight: LINE_HEIGHT_MULTIPLIER,
				// fontWeight: FONT_WEIGHT
			);

		ui.ParagraphBuilder pb = new ui.ParagraphBuilder(codeStyle);
		
		String numText = "0";
		pb.addText(numText);
		ui.Paragraph singleLine = pb.build()..layout(new ui.ParagraphConstraints(width: double.maxFinite));
		List<ui.TextBox> boxes = singleLine.getBoxesForRange(0, numText.length);
		this._glyphHeight = boxes.last.bottom - boxes.first.top;
		this._glyphWidth = boxes.last.right - boxes.first.left;
	}

	@override
	bool get sizedByParent => true;
	
	@override
	bool hitTestSelf(Offset offset) => true;

	@override
	void performResize() 
	{
		size = constraints.biggest;
	}

	@override
	performLayout()
	{
		super.performLayout();

		ui.ParagraphStyle codeStyle = new ui.ParagraphStyle(
					fontFamily: FONT_FAMILY,
					fontSize: FONT_SIZE,
					lineHeight: LINE_HEIGHT_MULTIPLIER,
					// fontWeight: FONT_WEIGHT
				);

		ui.ParagraphBuilder codePB = new ui.ParagraphBuilder(codeStyle);
		ui.ParagraphBuilder linesPB = new ui.ParagraphBuilder(
				new ui.ParagraphStyle(
					textAlign: TextAlign.right,
					fontFamily: FONT_FAMILY,
					fontSize: FONT_SIZE,
					lineHeight: LINE_HEIGHT_MULTIPLIER,
					// fontWeight: FONT_WEIGHT,
				)
			);
		ui.TextStyle semiTransparent = new ui.TextStyle(color: new Color.fromRGBO(255, 255, 255, 0.5));
		ui.TextStyle opaque = new ui.TextStyle(color: Colors.white);

		codePB.pushStyle(semiTransparent);
		linesPB.pushStyle(semiTransparent);
		ui.ParagraphConstraints codeConstraints = new ui.ParagraphConstraints(width: double.maxFinite);

		int maxNumDigits = _maxLines.toString().length;
		ui.ParagraphConstraints lineConstraints = new ui.ParagraphConstraints(width: maxNumDigits*_glyphWidth);
		
		String actualText = _text ?? "Loading...";
		List<String> lines = actualText.split('\n');

		int topLine = this.topLineNumber.clamp(0, lines.length - 1);

		double paragraphLineHeight = _glyphHeight;
		int maxVisibleLines = (size.height/paragraphLineHeight).ceil() + 2;
		List<String> visibleLines = lines.sublist(topLine, (topLine + maxVisibleLines).clamp(0, lines.length -1));

		int highlightStart = _highlight.row;
		int highlightEnd = _highlight.row + _highlight.howManyLines;

		for(int i = 0; i < visibleLines.length; i++)
		{
			String l = visibleLines[i].replaceAll('\t', "  ");
			ui.TextStyle lineStyle;
			int currentLine = topLine + i;
			if(currentLine >= highlightStart && currentLine < highlightEnd)
			{
				lineStyle = opaque;
			}
			else
			{
				lineStyle = semiTransparent;
			}
			codePB.pushStyle(lineStyle);
			codePB.addText("$l\n");
			codePB.pop();

			linesPB.pushStyle(lineStyle);
			linesPB.addText("${i+topLine}\n");
			linesPB.pop();
		}

		_codeParagraph = codePB.build()..layout(codeConstraints);
		_linesParagraph = linesPB.build()..layout(lineConstraints);
	}

	@override
	void paint(PaintingContext context, Offset offset)
	{
		offset = offset.translate(0.0, -2.0); // FIXME: fix  the node alignment instead of translating

		final Canvas canvas = context.canvas;
		canvas.save();
		canvas.clipRect(offset&size);

		int maxNumDigits = _maxLines.toString().length;
		Size linesRectSize = new Size(LINES_RECT_PADDING*2 + _glyphWidth*maxNumDigits, size.height);
		canvas.drawRect(offset&linesRectSize, new Paint()..color = new Color.fromARGB(51, 0, 0, 0));

		double codeBoxTop = offset.dy + CODE_PADDING_TOP;

		if(_highlight.howManyLines > 0)
		{
			Size highlightSize = new Size(size.width, 22.0);
			int highlightLineNumber = _highlight.row - this.topLineNumber;
			Offset highlightOffset = new Offset(
				offset.dx,
				codeBoxTop + _glyphHeight * highlightLineNumber + HIGHLIGHT_PADDING
			);
			canvas.drawRect(highlightOffset&highlightSize, new Paint()..color = new Color.fromARGB(_highlightAlpha, 255, 0, 108));
		}
		canvas.drawParagraph(_linesParagraph, new Offset(offset.dx + LINES_RECT_PADDING, codeBoxTop));
		canvas.drawParagraph(_codeParagraph, new Offset(offset.dx + linesRectSize.width + CODE_PADDING_LEFT, codeBoxTop));
		canvas.restore();
	}

	set highlight(Highlight h)
	{
		if(h != this._highlight)
		{
			this._highlight = h;
			// Try to keep the highlight always in the center of the scroll area
			// this.scrollValue = (h.row-10) * _glyphHeight;
			
			markNeedsLayout();
			markNeedsPaint();
		}
	}

	set scrollValue(double lineNumber)
	{
		lineNumber = max(lineNumber, 0.0);

		if(this._lineScrollOffset != lineNumber)
		{
			double max = (_maxLines-1) * _glyphHeight;

			// calcualte offset by line number and center of screen.
			double offset = lineNumber * _glyphHeight;

			offset -= size.height/2.0; // go down to center of screen
			offset += _glyphHeight/2.0; // go back up by half of the line

			this._lineScrollOffset = min(max, offset);

			markNeedsLayout();
			markNeedsPaint();
		}
	}

	set text(String value)
	{
		if(value == null)
		{
			// print("TRYING TO SET THE TEXT TO A NULL VALUE");
			return;
		}
		else if(this._text != value)
		{
			this._text = value;
			this._maxLines = this._text.split("\n").length;
			markNeedsLayout();
			markNeedsPaint();
		}
	}
	
	get topLineNumber => (_lineScrollOffset / _glyphHeight).floor();

	set highlightAlpha(int value)
	{
		if(this._highlightAlpha != value)
		{
			this._highlightAlpha = value;
			markNeedsPaint();
		}
	}

}