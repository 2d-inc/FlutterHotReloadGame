import "dart:ui" as ui;

import "package:flutter/material.dart";

import "../decorations/game_colors.dart";
import "../game.dart";
import "../game_provider.dart";
import "game_command_widget.dart";
import "game_radial.dart";
import "tick_paragraph.dart";

/// The [GameSlider] widget represents a horizontal line with 5 ticks, which can be shown during a game.
/// Players can interact with the slider either by sliding their finger, or by tapping directly on a certain tick value.
/// It needs to be a [StatefulWidget] so that it can animate between one state and the next, reacting to inputs.
class GameSlider extends StatefulWidget implements GameCommand
{
	final String taskType;
	final int value;
	final int min;
	final int max;

	GameSlider.make(this.taskType, Map params) : value = params['min'], min = params['min'], max = params['max'];
	
    /// Custom constructor that's need by the [InGame] widget whenever a [GameRadial] wouldn't have enough space in the grid,
    /// and it's replaced by a Slider instead.
	GameSlider.fromRadial(GameRadial radial) :
		taskType = radial.taskType,
		value = radial.value, min = radial.min, max = radial.max;

	@override
	GameSliderState createState() => new GameSliderState(value.toDouble(), min, max);
}

/// This [State] uses a [GestureDetector] to detect any dragging events on the whole render element, and
/// animates between a certain value and the new one registered by any possible event.
class GameSliderState extends State<GameSlider> with SingleTickerProviderStateMixin
{
    static const int NumSliderTicks = 5;
	final int minValue;
	final int maxValue;

	int targetValue = 0;
	double value = 0.0;
	double accumulation = 0.0;
	AnimationController _controller;
	Animation<double> _valueAnimation;

	GameSliderState(this.value, this.minValue, this.maxValue);
	
	void dragStart(DragStartDetails details)
	{
		dragToGlobal(details.globalPosition);
	}

    /// Convert the gesture position to local values and animate, if needed, to this new value.
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

    @override
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
				alignment: Alignment.center,
				child: new GameSliderNotches((value-minValue)/(maxValue-minValue), minValue, maxValue)
				)
			);
	}
}

/// The widget for rendering a custom [GameSliderNotchesRenderObject]. 
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

/// Custom renderer for the notched element in the grid, with 5 values. 
/// It'll draw a horizontal line with 5 ticks, a textual value above each tick representing the value associated with it.
class GameSliderNotchesRenderObject extends RenderBox
{
    static const padding = 40.0;
    static const strokeWidth = 10.0;
    static const double tickWidth = 10.0;
    static const double tickHeight = 15.0;

	double _value;
	int _minValue;
	int _maxValue;

	List<TickParagraph> _tickParagraphs;

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

    /// Lay out the all the Paragraphs needed the slider ticks.
	@override
	void performLayout()
	{
		super.performLayout();
		
		_tickParagraphs = new List<TickParagraph>(GameSliderState.NumSliderTicks);

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
			TickParagraph rtp = new TickParagraph()
															..paragraph = tickParagraph
															..size = new Size(boxes.last.right-boxes.first.left, boxes.last.bottom - boxes.first.top);
			_tickParagraphs[i] = rtp;
		}
	}
	
	@override
	void paint(PaintingContext context, Offset offset)
	{
		final Canvas canvas = context.canvas;

		final ui.Paint tickPaint = new ui.Paint()..color = GameColors.lowValueContent..strokeWidth = 2.0..style=PaintingStyle.stroke;
		final double tickHorizonalSpace = size.width-padding*2;
		final double tickX = offset.dx+padding;
		final double moveDown = size.height*0.75;

		for(int i = 0; i < GameSliderState.NumSliderTicks; i++)
		{
			double x = tickX + i*tickHorizonalSpace/(GameSliderState.NumSliderTicks-1);

			Offset p1 = new Offset(x, offset.dy+moveDown-strokeWidth/2.0);
			Offset p2 = new Offset(x, offset.dy+moveDown-strokeWidth/2.0-tickHeight);

			if(_tickParagraphs != null)
			{
				TickParagraph tickParagraph = _tickParagraphs[i];
                /// Draw each textual tick value first.
				canvas.drawParagraph(tickParagraph.paragraph, new Offset(p2.dx - tickParagraph.size.width/2.0, p2.dy - tickHeight - tickParagraph.size.height));
			}
			
            /// Then draw the tick line beneath the text.
			canvas.drawLine(p1, p2, tickPaint);
		}

		double upToX = offset.dx+padding+(size.width-padding*2.0)*_value;
        /// Draw the slider background line.
		canvas.drawLine(new Offset(offset.dx+padding, offset.dy+moveDown-strokeWidth/2.0), new Offset(offset.dx+size.width-padding, offset.dy+moveDown-strokeWidth/2.0), new ui.Paint()..color = GameColors.lowValueContent..strokeWidth = 10.0..style=PaintingStyle.stroke..strokeCap = StrokeCap.round);
        /// Draw the slider foreground highlighted line.
		canvas.drawLine(new Offset(offset.dx+padding, offset.dy+moveDown-strokeWidth/2.0), new Offset(upToX, offset.dy+moveDown-strokeWidth/2.0), new ui.Paint()..color = GameColors.highValueContent..strokeWidth = 10.0..style=PaintingStyle.stroke..strokeCap = StrokeCap.round);
        /// Draw two circles, one bigger and one smaller, beneath the last selected element.
		canvas.drawCircle(new Offset(upToX, offset.dy+moveDown-strokeWidth/2.0), 15.0, new ui.Paint()..color = Colors.white..strokeWidth = 2.0..style=PaintingStyle.stroke..strokeCap = StrokeCap.round);
		canvas.drawCircle(new Offset(upToX, offset.dy+moveDown-strokeWidth/2.0), 5.0, new ui.Paint()..color = Colors.white..strokeWidth = 2.0..style=PaintingStyle.fill..strokeCap = StrokeCap.round);
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