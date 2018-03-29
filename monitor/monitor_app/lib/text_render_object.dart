import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TextRenderObject extends RenderBox
{
	static const double DEFAULT_FONT_SIZE = 16.0;
	static const double DEFAULT_LINE_HEIGHT = 1.25;
	static const double LINE_NUM_WIDTH = 45.0;
	Offset screenOffset;
	String _text;
	Paint _paint;
	TextStyle style;
	final double fontSize;
	final double lineHeight;

	TextRenderObject({
		this.screenOffset: Offset.zero,
		this.fontSize: DEFAULT_FONT_SIZE,
		this.lineHeight: DEFAULT_LINE_HEIGHT,
		this.style: const TextStyle(
			fontFamily: "Terminus", 
			color: const Color(0xFFFFFFFF), 
			fontSize: DEFAULT_FONT_SIZE,
			height: DEFAULT_LINE_HEIGHT
			)
	}) : _paint = new Paint()..color = Colors.blueGrey, _text = "";

	@override
	bool get sizedByParent => true;
	
	@override
	bool hitTestSelf(Offset screenOffset) => true;

	@override
	void performResize() 
	{
		size = constraints.biggest;
		print("SIZE IS: $size");
	}

	@override
	void paint(PaintingContext context, Offset offset)
	{
		print("Paint");
		final Canvas canvas = context.canvas;

		double lineHeight = this.style.height * this.fontSize;

		double maxLines = size.height / lineHeight;
		double baseOffset = max(this.offset.dy, 0.0) / lineHeight;
		
		List<String> lines = this._text.split('\n');

		int startLine = max(0, baseOffset.floor());
		int endLine = min( lines.length, (startLine + maxLines).ceil() );

		List<String> visibleLines = lines.sublist(startLine, endLine);

		int lineNo = startLine;
		String visibleLineNumbers = "${startLine}";
		String visibleCodeLines = visibleLines[0];
		for(int i = 1; i < visibleLines.length; i++)
		{
			visibleCodeLines += "\n" + visibleLines[i];
			lineNo++;
			visibleLineNumbers += "\n$lineNo";
		}

		canvas.save();
		canvas.clipRect(offset & size);

		Size lineNumSize = new Size(LINE_NUM_WIDTH, size.height);
		Rect lineNumRect = offset & lineNumSize;
		canvas.drawRect(lineNumRect, new Paint()..color = new Color.fromARGB(255, 70, 70, 70));
		paintLines(canvas, offset, visibleLineNumbers);
		
		Offset textRectOffset = new Offset(offset.dx + LINE_NUM_WIDTH, offset.dy);
		Size textSize = new Size(size.width - LINE_NUM_WIDTH, size.height);
		canvas.drawRect(textRectOffset & textSize, new Paint()..color = Colors.transparent);
		// TODO: compute the highlight offset based on the linenumber
		Size highlightSize = new Size(textSize.width, lineHeight);
		Offset highlightOffset = new Offset(textRectOffset.dx, offset.dy + lineHeight * 10);
		canvas.drawRect(highlightOffset & highlightSize, new Paint()..color = const Color.fromARGB(100, 0, 180, 255));
		paintText(canvas, textRectOffset, visibleCodeLines);
		canvas.restore();	
	}

	

	paintLines(Canvas canvas, Offset offset, String lines)
	{
		TextSpan span = new TextSpan(
			style: this.style,
			text: lines
		);

		TextPainter tp = new TextPainter(
			text: span, 
			textAlign: TextAlign.right,
			textDirection: TextDirection.ltr
		);

		tp.layout(minWidth: LINE_NUM_WIDTH - 8 /* padding? */, maxWidth: LINE_NUM_WIDTH);
		tp.paint(canvas, offset);
	}

	void paintText(Canvas canvas, Offset offset, String lines)
	{
		TextSpan span = new TextSpan(
			style: this.style,
			text: lines
		);

		TextPainter tp = new TextPainter(
			text: span, 
			textAlign: TextAlign.left,
			textDirection: TextDirection.ltr
		);

		tp.layout();
		tp.paint(canvas, offset);
	}

	@override
	markNeedsPaint()
	{
		bool changed = false;
		double fontSizeFactor = 1.0;
		double lineHeightDelta = 0.0;
		if(this.fontSize != this.style.fontSize)
		{
			fontSizeFactor = this.fontSize / this.style.fontSize;
			changed = true;
		}
		if(this.lineHeight != this.style.height)
		{
			lineHeightDelta = this.lineHeight - this.style.height;
			changed = true;
		}
		if(changed)
		{
			this.style = this.style.apply(
				fontSizeFactor: fontSizeFactor,
				heightDelta: lineHeightDelta
			);
		}
		super.markNeedsPaint();
	}

	Offset get offset => this.screenOffset;

	set text(String value)
	{
		if(this._text != value)
		{
			this._text = value;
			markNeedsPaint();
		}
	}

}