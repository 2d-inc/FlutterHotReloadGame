import "dart:math";
import "dart:ui" as ui;

import "package:flutter/material.dart";

/// This widget is used in the main window, during a game, to show the stdout channel from the virtual terminal
/// that is running the Simulator, so that the 'Hot Reload' commands can be shown directly to anyone looking at the 
/// TV App.
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

/// This custom renderer clips out a rectangle box to properly show the terminal output, and draws a paragraph.
/// Moreover it paints a blinking cursor at the end of the output, for a more faithful representation.
class StdoutDisplayRenderer extends RenderBox
{
	String _output;
	ui.Paragraph _outputParagraph;
	TextBox _cursorBox;
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
			fontWeight: FontWeight.w700
		))..pushStyle(new ui.TextStyle(color:Colors.white));
		builder.addText(_output);
		_outputParagraph = builder.build();
		_outputParagraph.layout(new ui.ParagraphConstraints(width: size.width));
		if(_output.length > 0)
		{
			List<TextBox> boxes = _outputParagraph.getBoxesForRange(_output.length-1, _output.length);
			_cursorBox = boxes.first;
		}
	}

	@override
	void paint(PaintingContext context, Offset offset)
	{
		final Canvas canvas = context.canvas;
		canvas.save();
		canvas.clipRect(offset&size);
		Offset pos = new Offset(offset.dx, offset.dy - _outputParagraph.height + size.height);
		canvas.drawParagraph(_outputParagraph, pos);
		if(_cursorBox != null)
		{
			DateTime t = new DateTime.now();
			double blink = pow((1.0-(t.millisecondsSinceEpoch/900.0)%1.0*2.0).abs(), 0.8);
			const double boxPad = 0.0;
			canvas.drawRect(Rect.fromLTRB(_cursorBox.left + pos.dx + boxPad, _cursorBox.top + pos.dy + boxPad, _cursorBox.right + pos.dx - boxPad, _cursorBox.bottom + pos.dy - boxPad), new Paint()..color = new Color.fromRGBO(255, 255, 255, blink)..style=PaintingStyle.fill);
		}
		canvas.restore();
	}
}