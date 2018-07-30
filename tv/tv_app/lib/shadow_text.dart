import "dart:ui" as ui;

import "package:flutter/material.dart";

/// Implements a custom renderer to show a shadow underneath the text.
/// Can be passed in a number of parameters like [fontFamily], [fontSize], and [spacing].
class ShadowText extends LeafRenderObjectWidget
{
	final String text;
	final String fontFamily;
	final double fontSize;
	final double spacing;
	ShadowText(
		this.text,
		{
			Key key, 
			this.fontSize,
			this.spacing,
			this.fontFamily
		}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new ShadowTextRenderObject(text, fontFamily, fontSize, spacing);
	}

	@override
	void updateRenderObject(BuildContext context, covariant ShadowTextRenderObject renderObject)
	{
		renderObject..text = text
					..fontSize = fontSize
					..spacing = spacing
					..fontFamily = fontFamily;
	}
}

/// This renderer is used to draw the shadow text underneath a text widget.
/// To obtain this effect, two paragraphs are effectively drawn:
/// the background shadow paragraph, with a slight offset to show the shadow and the regular text paragraph,
class ShadowTextRenderObject extends RenderBox
{
	String _text;
	String _fontFamily;
	double _fontSize;
	double _spacing;

	ui.Paragraph _fgParagraph;
	ui.Paragraph _bgParagraph;

	ShadowTextRenderObject(String text, String fontFamily, double fontSize, double spacing)
	{
		this.fontFamily = fontFamily;
		this.text = text;
		this.fontSize = fontSize;
		this.spacing = spacing;
	}

	@override
	bool get sizedByParent => false;
	
	@override
	bool hitTestSelf(Offset screenOffset) => true;

	@override
	void performLayout()
	{
		if(text == null)
		{
			size = new Size(1.0, 1.0);
			return;
		}
		ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
			textAlign:TextAlign.start,
			fontFamily: _fontFamily,
			fontSize: fontSize ?? 10.0,
		))..pushStyle(new ui.TextStyle(color:Colors.white, letterSpacing:spacing));
		builder.addText(text);
		_fgParagraph = builder.build();
		_fgParagraph.layout(new ui.ParagraphConstraints(width: double.infinity));
		
		List<ui.TextBox> boxes = _fgParagraph.getBoxesForRange(0, text.length);

		size = new Size(boxes.last.right-boxes.first.left, boxes.last.bottom - boxes.first.top);

		builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
			textAlign:TextAlign.start,
			fontFamily: _fontFamily,
			fontSize: fontSize ?? 10.0,
		))..pushStyle(new ui.TextStyle(color:Colors.black, letterSpacing:spacing));
		builder.addText(text);
		_bgParagraph = builder.build();
		_bgParagraph.layout(new ui.ParagraphConstraints(width: double.infinity));
		markNeedsPaint();
	}
	
	@override
	void paint(PaintingContext context, Offset offset)
	{
		if(_fgParagraph == null)
		{
			return;
		}
		final Canvas canvas = context.canvas;
		canvas.drawParagraph(_bgParagraph, offset + const Offset(3.0, 4.0));
		canvas.drawParagraph(_fgParagraph, offset);
	}

	double get fontSize
	{
		return _fontSize;
	}

	set fontSize(double d)
	{
		if(_fontSize == d)
		{
			return;
		}
		_fontSize = d;
		markNeedsLayout();
	}

	double get spacing
	{
		return _spacing;
	}

	set spacing(double d)
	{
		if(_spacing == d)
		{
			return;
		}
		_spacing = d;
		markNeedsLayout();
	}

	String get text
	{
		return _text;
	}

	set text(String value)
	{
		if(_text == value)
		{
			return;
		}
		_text = value;

		markNeedsLayout();
	}

	String get fontFamily
	{
		return _fontFamily;
	}

	set fontFamily(String value)
	{
		if(_fontFamily == value)
		{
			return;
		}
		_fontFamily = value;

		markNeedsLayout();
	}
}
