import "dart:ui" as ui;

import "package:flutter/material.dart";

import "../decorations/game_colors.dart";
import "../game.dart";
import "../game_provider.dart";
import "game_command_widget.dart";
import "game_radial.dart";

class GameSlider extends StatefulWidget implements GameCommand
{
	GameSlider.make(this.taskType, Map params) : value = params['min'], min = params['min'], max = params['max'];
	
	GameSlider.fromRadial(GameRadial radial) :
		taskType = radial.taskType,
		value = radial.value, min = radial.min, max = radial.max;

	final String taskType;
	final int value;
	final int min;
	final int max;

	@override
	GameSliderState createState() => new GameSliderState(value.toDouble(), min, max);
}

class GameSliderState extends State<GameSlider> with SingleTickerProviderStateMixin
{
	AnimationController _controller;
	Animation<double> _valueAnimation;
	double value = 0.0;
	final int minValue;
	final int maxValue;
	double accumulation = 0.0;
	int targetValue = 0;

    static const int NumSliderTicks = 5;

	GameSliderState(this.value, this.minValue, this.maxValue);
	
	void dragStart(DragStartDetails details)
	{
		dragToGlobal(details.globalPosition);
	}

	void dragToGlobal(Offset offset)
	{
		RenderBox ro = context.findRenderObject();
		if(ro == null)
		{
			return;
		}
		Offset local = ro.globalToLocal(offset);

		const padding = 40.0;

		double tickHorizonalSpace = context.size.width-padding*2;
		double tickX = padding;

		double ds = tickHorizonalSpace/(NumSliderTicks-1);
		int tick = ((local.dx-tickX)/ds).round().clamp(0, NumSliderTicks-1);

		int v = (minValue + (maxValue-minValue)/(NumSliderTicks-1)*tick).round();

		if(targetValue == v)
		{
			return;
		}
		targetValue = v;

		
		_valueAnimation = new Tween<double>
		(
			begin: value.toDouble(),
			end: targetValue.toDouble()
		).animate(_controller);
	
		_controller
			..value = 0.0
			..animateTo(1.0, curve:Curves.easeOut);
	}

	void dragUpdate(DragUpdateDetails details)
	{
		dragToGlobal(details.globalPosition);
	}

	void dragEnd(DragEndDetails details, BuildContext context)
	{
        Game game = GameProvider.of(context);
        if(game.issueCommand != null)
        {
		    game.issueCommand(widget.taskType, targetValue);
        }
	}

	initState() 
	{
    	super.initState();
    	_controller = new AnimationController(duration: const Duration(milliseconds:200), vsync: this);
		_controller.addListener(()
		{
			setState(()
			{
				value = _valueAnimation.value;
			});
		});
	}

	@override
	void dispose()
	{
		_controller.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) 
	{
		return new GestureDetector(
			onVerticalDragStart: dragStart,
			onVerticalDragUpdate: dragUpdate,
			onVerticalDragEnd: (details) => dragEnd(details, context),
			child: new Container(
				alignment:Alignment.center,
				child:new GameSliderNotches((value-minValue)/(maxValue-minValue), minValue, maxValue)
				)
			);
	}
}


class GameSliderNotches extends LeafRenderObjectWidget
{
	final double value;
	final int minValue;
	final int maxValue;

	GameSliderNotches(this.value, this.minValue, this.maxValue,
		{
			Key key
		}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new GameSliderNotchesRenderObject(value, minValue, maxValue);
	}

	@override
	void updateRenderObject(BuildContext context, covariant GameSliderNotchesRenderObject renderObject)
	{
		renderObject..value = value
					..minValue = minValue
					..maxValue = maxValue;
	}
}

class SliderTickParagraph
{
	ui.Paragraph paragraph;
	Size size;
}

class GameSliderNotchesRenderObject extends RenderBox
{
	double _value;
	int _minValue;
	int _maxValue;

	ui.Paragraph _valueParagraph;
	Size _valueLabelSize;

	List<SliderTickParagraph> _tickParagraphs;

	GameSliderNotchesRenderObject(double value, int minValue, int maxValue)
	{
		this.value = value;
		this.minValue = minValue;
		this.maxValue = maxValue;
	}

	@override
	bool get sizedByParent => true;
	
	@override
	bool hitTestSelf(Offset screenOffset) => true;

	@override
	void performResize() 
	{
		size = new Size(constraints.constrainWidth(), constraints.constrainHeight(240.0));
	}

	@override
	void performLayout()
	{
		super.performLayout();
		
		_tickParagraphs = new List<SliderTickParagraph>(GameSliderState.NumSliderTicks);

		String valueLabel = (_minValue + _value*(_maxValue-_minValue)).round().toString();
		ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
			textAlign:TextAlign.start,
			fontFamily: "Inconsolata",
			fontSize: 36.0,
			fontWeight: FontWeight.w700
		))..pushStyle(new ui.TextStyle(color:GameColors.white));
		builder.addText(valueLabel);
		_valueParagraph = builder.build();

		_valueParagraph.layout(new ui.ParagraphConstraints(width: size.width));
		List<ui.TextBox> boxes = _valueParagraph.getBoxesForRange(0, valueLabel.length);
		_valueLabelSize = new Size(boxes.last.right-boxes.first.left, boxes.last.bottom - boxes.first.top);

		for(int i = 0; i < GameSliderState.NumSliderTicks; i++)
		{
			String tickLabel = (_minValue + (1.0/(GameSliderState.NumSliderTicks-1) * i) * (_maxValue-_minValue)).round().toString();
			ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
				textAlign:TextAlign.start,
				fontFamily: "Inconsolata",
				fontWeight: FontWeight.w700,
				fontSize: 16.0
			))..pushStyle(new ui.TextStyle(color:GameColors.highValueContent));
			builder.addText(tickLabel);
			ui.Paragraph tickParagraph = builder.build();
			tickParagraph.layout(new ui.ParagraphConstraints(width: size.width));
			List<ui.TextBox> boxes = tickParagraph.getBoxesForRange(0, tickLabel.length);
			SliderTickParagraph rtp = new SliderTickParagraph()
															..paragraph = tickParagraph
															..size = new Size(boxes.last.right-boxes.first.left, boxes.last.bottom - boxes.first.top);
			_tickParagraphs[i] = rtp;
			
		}
	}
	
	@override
	void paint(PaintingContext context, Offset offset)
	{
		final Canvas canvas = context.canvas;
		const padding = 40.0;
		const strokeWidth = 10.0;
		const double tickWidth = 10.0;
		const double tickHeight = 15.0;

		ui.Paint tickPaint = new ui.Paint()..color = GameColors.lowValueContent..strokeWidth = 2.0..style=PaintingStyle.stroke;

		double tickHorizonalSpace = size.width-padding*2;
		double tickX = offset.dx+padding;
		double moveDown = size.height*0.75;

		for(int i = 0; i < GameSliderState.NumSliderTicks; i++)
		{
			double x = tickX + i*tickHorizonalSpace/(GameSliderState.NumSliderTicks-1);

			Offset p1 = new Offset(x, offset.dy+moveDown-strokeWidth/2.0);
			Offset p2 = new Offset(x, offset.dy+moveDown-strokeWidth/2.0-tickHeight);

			if(_tickParagraphs != null)
			{
				SliderTickParagraph tickParagraph = _tickParagraphs[i];
				canvas.drawParagraph(tickParagraph.paragraph, new Offset(p2.dx - tickParagraph.size.width/2.0, p2.dy - tickHeight - tickParagraph.size.height));
			}
			

			canvas.drawLine(p1, p2, tickPaint);
		}

		double upToX = offset.dx+padding+(size.width-padding*2.0)*value;
		canvas.drawLine(new Offset(offset.dx+padding, offset.dy+moveDown-strokeWidth/2.0), new Offset(offset.dx+size.width-padding, offset.dy+moveDown-strokeWidth/2.0), new ui.Paint()..color = GameColors.lowValueContent..strokeWidth = 10.0..style=PaintingStyle.stroke..strokeCap = StrokeCap.round);
		canvas.drawLine(new Offset(offset.dx+padding, offset.dy+moveDown-strokeWidth/2.0), new Offset(upToX, offset.dy+moveDown-strokeWidth/2.0), new ui.Paint()..color = GameColors.highValueContent..strokeWidth = 10.0..style=PaintingStyle.stroke..strokeCap = StrokeCap.round);
		canvas.drawCircle(new Offset(upToX, offset.dy+moveDown-strokeWidth/2.0), 15.0, new ui.Paint()..color = Colors.white..strokeWidth = 2.0..style=PaintingStyle.stroke..strokeCap = StrokeCap.round);
		canvas.drawCircle(new Offset(upToX, offset.dy+moveDown-strokeWidth/2.0), 5.0, new ui.Paint()..color = Colors.white..strokeWidth = 2.0..style=PaintingStyle.fill..strokeCap = StrokeCap.round);
	}

	double get value
	{
		return _value;
	}

	set value(double v)
	{
		if(_value == v)
		{
			return;
		}
		_value = v;

		markNeedsLayout();
		markNeedsPaint();
	}

	int get minValue
	{
		return _minValue;
	}

	set minValue(int v)
	{
		if(_minValue == v)
		{
			return;
		}
		_minValue = v;

		markNeedsLayout();
		markNeedsPaint();
	}

	int get maxValue
	{
		return _maxValue;
	}

	set maxValue(int v)
	{
		if(_maxValue == v)
		{
			return;
		}
		_maxValue = v;

		markNeedsLayout();
		markNeedsPaint();
	}
}