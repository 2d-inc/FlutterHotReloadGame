import 'dart:collection';
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
	static const FontWeight FONT_WEIGHT = FontWeight.w700;
	static const double LINE_HEIGHT_MULTIPLIER = 18.0/16.0;
	static const double LINES_NUM_WIDTH = 60.0;
	static const int LINES_RECT_PADDING = 15;
	static const int CODE_PADDING_LEFT = 15;
	static const int CODE_PADDING_TOP = 10;
	static const int HIGHLIGHT_PADDING = 1;

	final HashSet<String> dartKeywords = new HashSet.from(["abstract", "deferred", "if", "super", "as", "do", "implements", "switch", "assert", "dynamic", "import", "sync*", "async", "else", "in", "this", "async*", "enum", "is", "throw", "await", "export", "library", "true", "break", "external", "new", "try", "case", "extends", "null", "typedef", "1", "catch", "factory", "operator", "var", "class", "false", "part", "void", "const", "final", "rethrow", "while", "continue", "finally", "return", "with", "covariant", "for", "set", "yield", "default", "get", "static", "yield*"]);

	final ui.ParagraphStyle codeStyle = new ui.ParagraphStyle(fontFamily: FONT_FAMILY, fontSize: FONT_SIZE, lineHeight: LINE_HEIGHT_MULTIPLIER, fontWeight: FONT_WEIGHT);
	final ui.ParagraphStyle linesStyle = new ui.ParagraphStyle(textAlign: TextAlign.right, fontFamily: FONT_FAMILY, fontSize: FONT_SIZE, fontWeight: FONT_WEIGHT, lineHeight: LINE_HEIGHT_MULTIPLIER);
	final ui.ParagraphConstraints codeConstraints = new ui.ParagraphConstraints(width: double.maxFinite);

	final ui.TextStyle opaque = new ui.TextStyle(color: Colors.white);
	final ui.TextStyle semiTransparent = new ui.TextStyle(color: new Color.fromRGBO(253, 205, 242, 0.6));
	
	String _text;
	TextStyle style;
	Highlight _highlight;
	int _highlightAlpha;
	int _maxLines;
	double _lineScrollOffset;
	double _glyphHeight = 10.0;
	double _glyphWidth = 10.0;

	List<ui.Paragraph> _codeParagraphs;
	List<ui.Paragraph> _linesParagraphs;

	TextRenderObject() : 
		this._codeParagraphs = [],
		this._linesParagraphs = [],
		this._lineScrollOffset = 0.0,
		this._highlight = new Highlight(100, 0, 0),
		this._highlightAlpha = 56
	{
		// Initialize the Line Height for this style
		ui.ParagraphBuilder pb = new ui.ParagraphBuilder(codeStyle);
		
		String numText = "0";
		pb.addText(numText);
		ui.Paragraph singleLine = pb.build()..layout(new ui.ParagraphConstraints(width: double.maxFinite));
		List<ui.TextBox> boxes = singleLine.getBoxesForRange(0, numText.length);
		this._glyphHeight = singleLine.height;
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
		_codeParagraphs.clear();
		_linesParagraphs.clear();
		int maxNumDigits = _maxLines.toString().length;
		ui.ParagraphConstraints lineConstraints = new ui.ParagraphConstraints(width: maxNumDigits*_glyphWidth);
		
		String actualText = _text ?? "Loading...";
		List<String> lines = actualText.split('\n');

		int highlightStart = _highlight.row;
		int highlightEnd = _highlight.row + _highlight.howManyLines;

		double codeBoxHeight = 0.0;
		int i = topLineNumber;
		while(codeBoxHeight < size.height && i < lines.length - 1)
		{
			String l = lines[i].replaceAll('\t', "  ");
			bool isHighlight = i >= highlightStart && i < highlightEnd;
			codeBoxHeight += styleLine(l, isHighlight);
			
			final ui.ParagraphBuilder linesPB = new ui.ParagraphBuilder(linesStyle);
			linesPB.pushStyle(isHighlight ? opaque : semiTransparent);
			linesPB.addText("$i");
			linesPB.pop();
			_linesParagraphs.add(linesPB.build()..layout(lineConstraints));
			i++;
		}
		int numLines = i - topLineNumber;
		this._glyphHeight = codeBoxHeight/numLines;
	}
	
	double styleLine(String line, bool isOpaque)
	{
		ui.ParagraphBuilder codePB = new ui.ParagraphBuilder(codeStyle);
		double alpha = isOpaque ? 1.0 : 0.6;
		StringBuffer buf = new StringBuffer();
		RegExp alphabetic = new RegExp(r"[a-zA-Z]+");
		for(int i = 0; i <= line.length; i++)
		{
			// If the last character on the line is an alpabetic char, make sure that the buffer is emptied
			String currentChar = i < line.length ?  line[i] : ""; 
			bool isAlphabetic = alphabetic.hasMatch(currentChar);
			if(isAlphabetic)
			{
				buf.write(currentChar);
			}
			else if(currentChar == '/')
			{
				if((i+1) < line.length && line[i+1] == '/')
				{
					final ui.TextStyle comment = new ui.TextStyle(color: new Color.fromRGBO(144, 112, 137, alpha), fontWeight: FONT_WEIGHT);
					codePB.pushStyle(comment);
					codePB.addText(line.substring(i, line.length-1));
					codePB.pop();
					i = line.length; // break out of the loop
				}
			}
			else if (currentChar == "\'" || currentChar == "\"")
			{
				final ui.TextStyle string = new ui.TextStyle(color: new Color.fromRGBO(255, 0, 108, alpha), fontWeight: FONT_WEIGHT);
				int stringEndIdx = line.indexOf(currentChar, i+1);
				String s = line.substring(i, stringEndIdx + 1);
				codePB.pushStyle(string);
				codePB.addText(s);
				codePB.pop();
				i = stringEndIdx;
			}
			else
			{
				String word = buf.toString();
				buf.clear();
				if(dartKeywords.contains(word))
				{
					final ui.TextStyle keyword = new ui.TextStyle(color: new Color.fromRGBO(133, 226, 255, alpha), fontWeight: FONT_WEIGHT);
					codePB.pushStyle(keyword);
					codePB.addText(word);
					codePB.pop();
					codePB.addText(currentChar);
				}
				else
				{
					codePB.pushStyle(isOpaque ? opaque : semiTransparent);
					codePB.addText(word + currentChar);
					codePB.pop();
				}
			}
		}

		var paragraph = codePB.build()..layout(codeConstraints);
		_codeParagraphs.add(paragraph);
		return paragraph.height;
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

		for(int i = 0; i < _codeParagraphs.length; i++)
		{
			var cp = _codeParagraphs[i];
			var lp = _linesParagraphs[i];
			double yOffset = codeBoxTop + i*cp.height;
			if(_highlight.row - topLineNumber == i && _highlight.howManyLines > 0)
			{
				Size highlightSize = new Size(size.width, 22.0);
				Offset highlightOffset = new Offset(offset.dx, yOffset);
				canvas.drawRect(highlightOffset&highlightSize, new Paint()..color = new Color.fromARGB(_highlightAlpha, 255, 0, 108));
			}
			canvas.drawParagraph(cp, new Offset(offset.dx + linesRectSize.width + CODE_PADDING_LEFT, yOffset));
			canvas.drawParagraph(lp, new Offset(offset.dx + LINES_RECT_PADDING, yOffset));

		}
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

			if(size == null)
			{
				offset -= size.height/2.0; // go down to center of screen
				offset += _glyphHeight/2.0; // go back up by half of the line
			}

			this._lineScrollOffset = offset.clamp(0.0, max);

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
	
	int get topLineNumber => (_lineScrollOffset / _glyphHeight).floor();

	set highlightAlpha(int value)
	{
		if(this._highlightAlpha != value)
		{
			this._highlightAlpha = value;
			markNeedsPaint();
		}
	}

}