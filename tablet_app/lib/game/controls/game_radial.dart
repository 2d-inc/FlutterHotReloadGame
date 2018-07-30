import "dart:math";
import "dart:ui" as ui;

import "package:flutter/material.dart";

import "../decorations/game_colors.dart";
import "../game.dart";
import "../game_provider.dart";
import "game_command_widget.dart";
import "tick_paragraph.dart";

/// This widget draws an arc with a finite number of ticks and values, that can be selected by a user during a game.
/// It's a [StatefulWidget] so that it can maintain its status and animate when a drags or taps on a radial element.
/// It relies on a 
class GameRadial extends StatefulWidget implements GameCommand
{
    static const int NumRadialTicks = 5;
    static const double ArrowWidth = 16.0;
    static const double ArrowHeight = 10.0;
    static const double padding = 40.0;
    static const double arrowPadding = 30.0;
    static const double open = 0.25;
    static const double sweep = pi*2.0*(1.0-open);
    static const double startAngle = pi/2.0+(pi*open);

	final String taskType;
	final int value;
	final int min;
	final int max;

	GameRadial.make(this.taskType, Map params) : value = params['min'], min = params['min'], max = params['max'];
	
	@override
	_GameRadialState createState() => new _GameRadialState(value.toDouble(), min, max);
}

/// This element uses a [GestureDetector] to react to taps and slides; it builds a custom layout using a 
/// [GameRadialNotches] widget, which uses a custom [RenderBox].
/// The element visually is represented by an arc around a number, with two arrows above and below.
/// This is to signify that a user can drag upwards or downwards to input a new value. 
/// Tapping a tick value also is an option.
class _GameRadialState extends State<GameRadial> with SingleTickerProviderStateMixin
{
	final int minValue;
	final int maxValue;

	AnimationController _controller;
	Animation<double> _valueAnimation;
	int targetValue = 0;
	double value = 0.0;
	double accumulation = 0.0;

	_GameRadialState(this.value, this.minValue, this.maxValue);
	
	int getCurrentTick()
	{
		int closestTick = minValue;
		double closestDiff = double.maxFinite;
		for(int i = 0; i < GameRadial.NumRadialTicks; i++)
		{
			int tickValue = (minValue + (1.0/(GameRadial.NumRadialTicks-1) * i) * (maxValue-minValue)).round();
			double diff = (tickValue-value).abs();
			if(diff < closestDiff)
			{
				closestDiff = diff;
				closestTick = i;
			}
		}
		return closestTick;
	}

	int getCurrentTickValue()
	{
		int closestValue = minValue;
		double closestDiff = double.maxFinite;
		for(int i = 0; i < GameRadial.NumRadialTicks; i++)
		{
			int tickValue = (minValue + (1.0/(GameRadial.NumRadialTicks-1) * i) * (maxValue-minValue)).round();
			double diff = (tickValue-value).abs();
			if(diff < closestDiff)
			{
				closestDiff = diff;
				closestValue = tickValue;
			}
		}
		return closestValue;
	}

	int getTickValue(int i)
	{
		return (minValue + (1.0/(GameRadial.NumRadialTicks-1) * i.clamp(0, GameRadial.NumRadialTicks-1)) * (maxValue-minValue)).round();
	}

    double normalizeAngle(double angle)
    {
        return (angle+pi*2)%(pi*2);
    }

    /// This function is associated with the [GestureDetector] in the build function.
    /// It performs some calculations to disambiguate between which tick value in the Radial element is closer
    /// to the last touch position.
	void dragStart(DragStartDetails details, Game game)
	{
		RenderBox ro = context.findRenderObject();
		if(ro == null)
		{
			return;
		}
		Offset local = ro.globalToLocal(details.globalPosition);
		
		Offset pos = new Offset(GameRadial.padding, GameRadial.padding);
		Size arcSize = new Size(ro.size.width-GameRadial.padding*2, ro.size.height-GameRadial.padding*2);
		Offset center = new Offset(pos.dx + arcSize.width/2.0, pos.dy + arcSize.height/2.0);
		Offset diff = local-center;
		double angle = atan2(diff.dy, diff.dx);

		Offset arrow1 = new Offset(center.dx, center.dy - GameRadial.arrowPadding - GameRadial.ArrowHeight/2.0);
		Offset arrow2 = new Offset(center.dx, center.dy + GameRadial.arrowPadding + GameRadial.ArrowHeight/2.0);
		
		int closestValue = minValue;
		if((arrow1-local).distance < GameRadial.ArrowWidth)
		{
			closestValue = getTickValue(getCurrentTick() + 1);
		}
		else if((arrow2-local).distance < GameRadial.ArrowWidth)
		{
			closestValue = getTickValue(getCurrentTick() - 1);
		}
		else
		{
			double closest = 640.0;
			
			for(int i = 0; i < GameRadial.NumRadialTicks; i++)
			{
				double tickAngle = GameRadial.startAngle + i * GameRadial.sweep/(GameRadial.NumRadialTicks-1);
				double diff = (normalizeAngle(tickAngle)-normalizeAngle(angle)).abs();
				if(diff < closest)
				{
					closestValue = (minValue + (1.0/(GameRadial.NumRadialTicks-1) * i) * (maxValue-minValue)).round();
					closest = diff;
				}
			}
		}

		_valueAnimation = new Tween<double>
		(
			begin: value.toDouble(),
			end: closestValue.toDouble()
		).animate(_controller);

		_controller
			..value = 0.0
			..animateTo(1.0, curve:Curves.easeInOut);

		targetValue = closestValue;
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
        Game game = GameProvider.of(context);
		return new GestureDetector(
            /// Only detect vertical drag events.
			onVerticalDragStart: (details) => dragStart(details, game),
			child: new Container(
				alignment:Alignment.center,
				child: new GameRadialNotches((value-minValue)/(maxValue-minValue), minValue, maxValue)
				)
			);
	}
}

class GameRadialNotches extends LeafRenderObjectWidget
{
	final double value;
	final int minValue;
	final int maxValue;

	GameRadialNotches(this.value, this.minValue, this.maxValue,
		{
			Key key
		}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new GameRadialNotchesRenderObject(value, minValue, maxValue);
	}

	@override
	void updateRenderObject(BuildContext context, covariant GameRadialNotchesRenderObject renderObject)
	{
		renderObject..value = value
					..minValue = minValue
					..maxValue = maxValue;
	}
}

/// Custom renderer for the radial element in the grid, with 5 values. 
/// It'll draw an arc with 5 ticks, a textual value in the middle of the arc, and two arrows above and below this value.
class GameRadialNotchesRenderObject extends RenderBox
{
    static const double tickLength = 25.0;
    static const double tickTextLength = 35.0;

	double _value;
	int _minValue;
	int _maxValue;

    /// This [ui.Path] is used to draw the arrows above and below the text.
	ui.Path _arrowPath;
    /// [Paragraph] for the text.
	ui.Paragraph _valueParagraph;
	Size _valueLabelSize;

    /// List of [Paragraph]s for the 5 ticks.
	List<TickParagraph> _tickParagraphs;

	GameRadialNotchesRenderObject(double value, int minValue, int maxValue)
	{
		this.value = value;
		this.minValue = minValue;
		this.maxValue = maxValue;

		_arrowPath = new ui.Path();
		_arrowPath.moveTo(-GameRadial.ArrowWidth/2.0, 0.0);
		_arrowPath.lineTo(0.0, -GameRadial.ArrowHeight);
		_arrowPath.lineTo(GameRadial.ArrowWidth/2.0, 0.0);
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

        /// Lay out the value in the middle of the widget first.
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
        /// [getBoxesForRange()] makes the calculations in the layout process more precise.
		List<ui.TextBox> boxes = _valueParagraph.getBoxesForRange(0, valueLabel.length);
		_valueLabelSize = new Size(boxes.last.right-boxes.first.left, boxes.last.bottom - boxes.first.top);

		_tickParagraphs = new List<TickParagraph>(GameRadial.NumRadialTicks);
        /// Start building also all the ticks.
		for(int i = 0; i < GameRadial.NumRadialTicks; i++)
		{
			String tickLabel = (_minValue + (1.0/(GameRadial.NumRadialTicks-1) * i) * (_maxValue-_minValue)).round().toString();
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

        /// Get the location of this [RenderBox] by considering also its padding.
		Offset pos = new Offset(GameRadial.padding+offset.dx, GameRadial.padding + offset.dy);
        /// Start off by calculating the size of the main arc.
		Size arcSize = new Size(size.width-GameRadial.padding*2, size.height-GameRadial.padding*2);

		final double radius = min(arcSize.width, arcSize.height)/2.0;
		final double radiusTickStart = radius-tickLength/2.0;
		final double radiusTickEnd = radius+tickLength/2.0;
		final double radiusTickText = radius+tickTextLength;

		ui.Paint tickPaint = new ui.Paint()..color = GameColors.lowValueContent..strokeWidth = 2.0..style=PaintingStyle.stroke;

        /// Give the arc size, get the central coordinates.
		Offset center = new Offset(pos.dx + arcSize.width/2.0, pos.dy + arcSize.height/2.0);
		Offset arcPaintOffset = new Offset(pos.dx + arcSize.width/2.0 - radius, pos.dy + arcSize.height/2.0 - radius);
		Size arcPaintSize = new Size(radius*2.0, radius*2.0);
		for(int i = 0; i < GameRadial.NumRadialTicks; i++)
		{
			double angle = GameRadial.startAngle + i * GameRadial.sweep/(GameRadial.NumRadialTicks-1);

			double c = cos(angle);
			double s = sin(angle);

			Offset p1 = new Offset(center.dx+c * radiusTickStart, center.dy+s * radiusTickStart);
			Offset p2 = new Offset(center.dx+c * radiusTickEnd, center.dy+s * radiusTickEnd);

			if(_tickParagraphs != null)
			{
				TickParagraph tickParagraph = _tickParagraphs[i];
				Offset tickTextPosition = new Offset(center.dx+c * radiusTickText, center.dy+s * radiusTickText);
                /// Draw the tick textual element first.
				canvas.drawParagraph(tickParagraph.paragraph, new Offset(tickTextPosition.dx - tickParagraph.size.width/2.0, tickTextPosition.dy - tickParagraph.size.height/2.0));
			}
            /// Draw the actual tick.
			canvas.drawLine(p1, p2, tickPaint);
		}
        /// Draw the arc around the central element.
		canvas.drawArc(arcPaintOffset & arcPaintSize, GameRadial.startAngle, GameRadial.sweep, false, new ui.Paint()..color = GameColors.lowValueContent..strokeWidth = 10.0..style=PaintingStyle.stroke..strokeCap = StrokeCap.round);
		canvas.drawArc(arcPaintOffset & arcPaintSize, GameRadial.startAngle, GameRadial.sweep*_value, false, new ui.Paint()..color = GameColors.highValueContent..strokeWidth = 10.0..style=PaintingStyle.stroke..strokeCap = StrokeCap.round);

        /// Lastly draw the central textual element, together with the two arrow visual elements below and above.
		ui.Paint arrowPaint = new ui.Paint()..color = GameColors.midValueContent..strokeWidth = 1.0..style=PaintingStyle.stroke;
		canvas.drawParagraph(_valueParagraph, new Offset(center.dx - _valueLabelSize.width/2.0, center.dy - _valueLabelSize.height/2.0));
		canvas.save();
		canvas.translate(center.dx, center.dy - GameRadial.arrowPadding);
		canvas.drawPath(_arrowPath, arrowPaint);
		canvas.restore();
		canvas.save();
		
		canvas.translate(center.dx, center.dy + GameRadial.arrowPadding);
		canvas.scale(1.0, -1.0);
		canvas.drawPath(_arrowPath, arrowPaint);
		canvas.restore();
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