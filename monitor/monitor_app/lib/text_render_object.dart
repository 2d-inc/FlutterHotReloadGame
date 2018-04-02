import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TextRenderObject extends RenderBox
{
	static const double FONT_SIZE = 17.0;
	static const String FONT_FAMILY = "RobotoMono";
	static const double LINES_NUM_WIDTH = 60.0;

	String _text;
	TextStyle style;
	int _highlightOffset;
	int _highlightedRows;
	int _maxLines;
	double _lineScrollOffset;
	double _lineHeight;

	ui.Paragraph _codeParagraph;
	ui.Paragraph _linesParagraph;

	TextRenderObject() : 
		this._lineScrollOffset = 0.0,
		this._highlightOffset = 5,
		this._highlightedRows = 3
	{
		// Initialize the Line Height for this style
		ui.ParagraphStyle codeStyle = new ui.ParagraphStyle(
				fontFamily: FONT_FAMILY,
				fontSize: FONT_SIZE
			);

		ui.ParagraphBuilder pb = new ui.ParagraphBuilder(codeStyle);
		pb.addText("Loading...");
		ui.Paragraph singleLine = pb.build()..layout(new ui.ParagraphConstraints(width: double.maxFinite));
		this._lineHeight = singleLine.height;
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
					fontSize: FONT_SIZE
				);

		ui.ParagraphBuilder codePB = new ui.ParagraphBuilder(codeStyle);
		ui.ParagraphBuilder linesPB = new ui.ParagraphBuilder(
				new ui.ParagraphStyle(
					textAlign: TextAlign.right,
					fontFamily: FONT_FAMILY,
					fontSize: FONT_SIZE
				)
			);

		ui.ParagraphConstraints codeConstraints = new ui.ParagraphConstraints(width: double.maxFinite);
		ui.ParagraphConstraints lineConstraints = new ui.ParagraphConstraints(width: 50.0);
		
		String actualText = this._text ?? "Loading...";
		List<String> lines = actualText.split('\n');

		int currentLineNum = (_lineScrollOffset / _lineHeight).floor();
		double maxHeight = size.height;
		double currentHeight = 0.0;

		String visibleText = lines[currentLineNum].replaceAll('\t', "  ");
		String visibleLineNums = currentLineNum.toString();

		for(int i = currentLineNum + 1;
			i < lines.length && currentHeight < maxHeight; 
			++i, ++currentLineNum)
		{
			visibleText += "\n" + lines[i].replaceAll('\t', "  ");
			visibleLineNums += '\n$i';
			
			ui.ParagraphBuilder tempPB = new ui.ParagraphBuilder(codeStyle);
			
			tempPB.addText(visibleText);
			ui.Paragraph _tempParagraph = tempPB.build()
				..layout(codeConstraints);

			// Adjust the scrolling to be continuous
			currentHeight = _tempParagraph.height - (_lineScrollOffset % _lineHeight);
		}

		codePB.addText(visibleText);
		_codeParagraph = codePB.build()..layout(codeConstraints);
		linesPB.addText(visibleLineNums);
		_linesParagraph = linesPB.build()..layout(lineConstraints);
	}

	@override
	void paint(PaintingContext context, Offset offset)
	{
		final Canvas canvas = context.canvas;
		canvas.save();
		canvas.clipRect(offset&size);
		// TODO: remove
		// Size codeBoxSize = new Size(size.width - LINES_NUM_WIDTH, size.height);
		// Offset codeBoxOffset = new Offset(offset.dx + LINES_NUM_WIDTH, offset.dy);
		// canvas.drawRect(codeBoxOffset&size, new Paint()..color = new Color.fromARGB(200, 70, 70, 70));
		//
		Size lineRectSize = new Size(LINES_NUM_WIDTH, size.height);
		canvas.drawRect(offset&lineRectSize, new Paint()..color = new Color.fromARGB(200, 59, 60, 61));

		double scrollAdjustment = (_lineScrollOffset % _lineHeight);
		Size highlightSize = new Size(size.width - LINES_NUM_WIDTH, _lineHeight * _highlightedRows);
		Offset highlightOffset = new Offset(offset.dx + LINES_NUM_WIDTH, offset.dy + _lineHeight*this._highlightOffset - scrollAdjustment);
		RRect rounded = new RRect.fromRectXY(highlightOffset&highlightSize, 5.0, 5.0);
		canvas.drawRRect(rounded, new Paint()..color = const Color.fromARGB(100, 0, 180, 255));

		canvas.drawParagraph(_linesParagraph, new Offset(offset.dx, offset.dy - scrollAdjustment ));
		const int CODE_PADDING = 10;
		canvas.drawParagraph(_codeParagraph, new Offset(offset.dx + LINES_NUM_WIDTH + CODE_PADDING, offset.dy - scrollAdjustment));
		canvas.restore();
	}

	set scrollValue(double value)
	{
		if(this._lineScrollOffset != value && value >= 0)
		{
			double max = _maxLines * _lineHeight;
			this._lineScrollOffset = min(max, value);

			markNeedsLayout();
			markNeedsPaint();
		}
	}

	setHighlight(int lineNumber, int howMany)
	{
		bool changed = false;
		if(this._highlightOffset != lineNumber)
		{
			this._highlightOffset = lineNumber;
			changed = true;
		}

		if(this._highlightedRows != howMany)
		{
			this._highlightedRows = howMany;
			changed = true;
		}

		if(changed)
		{
			markNeedsLayout();
			markNeedsPaint();
		}
	}

	set text(String value)
	{
		if(value == null)
		{
			print("TRYING TO SET THE TEXT TO A NULL VALUE");
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
}