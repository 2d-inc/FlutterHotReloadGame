import "package:flutter/material.dart";
import "dart:ui" as ui;
import "dart:math";
import "dart:typed_data";
import "package:flutter/scheduler.dart";

class StdoutDisplay extends LeafRenderObjectWidget
{
	final String output;

	StdoutDisplay(this.output, { Key key }) : super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new StdoutDisplayRenderer(output);
	}

	@override
	void updateRenderObject(BuildContext context, covariant StdoutDisplayRenderer renderObject)
	{
		renderObject..output = output;
	}
}

class StdoutDisplayRenderer extends RenderBox
{
	String _output;
	ui.Paragraph _outputParagraph;

	StdoutDisplayRenderer(String output)
	{
		this.output = output;
	}

	String get output
	{
		return _output;
	}

	set output(String value)
	{
		if(_output == value)
		{
			return;
		}
		_output = value;
		markNeedsLayout();
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
	void performLayout()
	{
		super.performLayout();
		
		ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
			textAlign:TextAlign.start,
			fontFamily: "Inconsolata",
			fontSize: 16.0,
			lineHeight: 18.0,
			fontWeight: FontWeight.w700
		))..pushStyle(new ui.TextStyle(color:Colors.white));
		builder.addText(_output);
		_outputParagraph = builder.build();

		_outputParagraph.layout(new ui.ParagraphConstraints(width: size.width));
	}

	@override
	void paint(PaintingContext context, Offset offset)
	{
		final Canvas canvas = context.canvas;
		canvas.save();
		canvas.clipRect(offset&size);
		canvas.drawParagraph(_outputParagraph, new Offset(offset.dx, offset.dy - _outputParagraph.height + size.height));
		canvas.restore();
	}
}