import "package:flutter/material.dart";
import "dart:ui" as ui;
import "dart:math";
import "game_colors.dart";
import "game_command_widget.dart";

class GameRadial extends StatefulWidget implements GameCommand
{
	GameRadial.make(this.issueCommand, this.taskType, Map params) : value = params['min'], min = params['min'], max = params['max'];
	
	final String taskType;
	final int value;
	final int min;
	final int max;
	final IssueCommandCallback issueCommand;

	@override
	_GameRadialState createState() => new _GameRadialState(value.toDouble(), min, max);
}

const double ArrowWidth = 16.0;
const double ArrowHeight = 10.0;
const int NumRadialTicks = 5;

const double padding = 40.0;
const double open = 0.25;
final double sweep = pi*2.0*(1.0-open);
const double tickLength = 25.0;
const double tickTextLength = 35.0;
final double startAngle = pi/2.0+(pi*open);
const double arrowPadding = 30.0;

double normalizeAngle(double angle)
{
	return (angle+pi*2)%(pi*2);
}

class _GameRadialState extends State<GameRadial> with SingleTickerProviderStateMixin
{
	AnimationController _controller;
	Animation<double> _valueAnimation;
	double value = 0.0;
	final int minValue;
	final int maxValue;
	double accumulation = 0.0;
	int targetValue = 0;

	_GameRadialState(this.value, this.minValue, this.maxValue);
	
	int getCurrentTick()
	{
		int closestTick = minValue;
		double closestDiff = double.maxFinite;
		for(int i = 0; i < NumRadialTicks; i++)
		{
			int tickValue = (minValue + (1.0/(NumRadialTicks-1) * i) * (maxValue-minValue)).round();
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
		for(int i = 0; i < NumRadialTicks; i++)
		{
			int tickValue = (minValue + (1.0/(NumRadialTicks-1) * i) * (maxValue-minValue)).round();
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
		return (minValue + (1.0/(NumRadialTicks-1) * i.clamp(0, NumRadialTicks-1)) * (maxValue-minValue)).round();
	}

	void dragStart(DragStartDetails details)
	{
		RenderBox ro = context.findRenderObject();
		if(ro == null)
		{
			return;
		}
		Offset local = ro.globalToLocal(details.globalPosition);

		
		Offset pos = new Offset(padding, padding);
		Size arcSize = new Size(ro.size.width-padding*2, ro.size.height-padding*2);
		//final double radius = min(arcSize.width, arcSize.height)/2.0;
		Offset center = new Offset(pos.dx + arcSize.width/2.0, pos.dy + arcSize.height/2.0);
		Offset diff = local-center;
		double angle = atan2(diff.dy, diff.dx);

		Offset arrow1 = new Offset(center.dx, center.dy - arrowPadding - ArrowHeight/2.0);
		Offset arrow2 = new Offset(center.dx, center.dy + arrowPadding + ArrowHeight/2.0);
		
		int closestValue = minValue;
		if((arrow1-local).distance < ArrowWidth)
		{
			closestValue = getTickValue(getCurrentTick() + 1);
		}
		else if((arrow2-local).distance < ArrowWidth)
		{
			closestValue = getTickValue(getCurrentTick() - 1);
		}
		else
		{
			double closest = 640.0;
			
			for(int i = 0; i < NumRadialTicks; i++)
			{
				double tickAngle = startAngle + i * sweep/(NumRadialTicks-1);
				double diff = (normalizeAngle(tickAngle)-normalizeAngle(angle)).abs();
				if(diff < closest)
				{
					closestValue = (minValue + (1.0/(NumRadialTicks-1) * i) * (maxValue-minValue)).round();
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
		widget.issueCommand(widget.taskType, targetValue);
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
			child: new Container(
				alignment:Alignment.center,
				child:new GameRadialNotches((value-minValue)/(maxValue-minValue), minValue, maxValue)
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

class RadialTickParagraph
{
	ui.Paragraph paragraph;
	Size size;
}

class GameRadialNotchesRenderObject extends RenderBox
{
	double _value;
	int _minValue;
	int _maxValue;

	ui.Paragraph _valueParagraph;
	Size _valueLabelSize;

	ui.Path _arrowPath;

	List<RadialTickParagraph> _tickParagraphs;

	GameRadialNotchesRenderObject(double value, int minValue, int maxValue)
	{
		this.value = value;
		this.minValue = minValue;
		this.maxValue = maxValue;

		_arrowPath = new ui.Path();
		_arrowPath.moveTo(-ArrowWidth/2.0, 0.0);
		_arrowPath.lineTo(0.0, -ArrowHeight);
		_arrowPath.lineTo(ArrowWidth/2.0, 0.0);
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
		
		_tickParagraphs = new List<RadialTickParagraph>(NumRadialTicks);

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

		for(int i = 0; i < NumRadialTicks; i++)
		{
			String tickLabel = (_minValue + (1.0/(NumRadialTicks-1) * i) * (_maxValue-_minValue)).round().toString();
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
			RadialTickParagraph rtp = new RadialTickParagraph()
															..paragraph = tickParagraph
															..size = new Size(boxes.last.right-boxes.first.left, boxes.last.bottom - boxes.first.top);
			_tickParagraphs[i] = rtp;
			
		}
	}
	
	@override
	void paint(PaintingContext context, Offset offset)
	{
		final Canvas canvas = context.canvas;

		Offset pos = new Offset(padding+offset.dx, padding + offset.dy);
		Size arcSize = new Size(size.width-padding*2, size.height-padding*2);

		final double radius = min(arcSize.width, arcSize.height)/2.0;

		final double radiusTickStart = radius-tickLength/2.0;
		final double radiusTickEnd = radius+tickLength/2.0;
		final double radiusTickText = radius+tickTextLength;

		ui.Paint tickPaint = new ui.Paint()..color = GameColors.lowValueContent..strokeWidth = 2.0..style=PaintingStyle.stroke;

		Offset center = new Offset(pos.dx + arcSize.width/2.0, pos.dy + arcSize.height/2.0);
		Offset arcPaintOffset = new Offset(pos.dx + arcSize.width/2.0 - radius, pos.dy + arcSize.height/2.0 - radius);
		Size arcPaintSize = new Size(radius*2.0, radius*2.0);
		for(int i = 0; i < NumRadialTicks; i++)
		{
			double angle = startAngle + i * sweep/(NumRadialTicks-1);

			double c = cos(angle);
			double s = sin(angle);

			Offset p1 = new Offset(center.dx+c * radiusTickStart, center.dy+s * radiusTickStart);
			Offset p2 = new Offset(center.dx+c * radiusTickEnd, center.dy+s * radiusTickEnd);

			if(_tickParagraphs != null)
			{
				RadialTickParagraph tickParagraph = _tickParagraphs[i];
				Offset tickTextPosition = new Offset(center.dx+c * radiusTickText, center.dy+s * radiusTickText);
				canvas.drawParagraph(tickParagraph.paragraph, new Offset(tickTextPosition.dx - tickParagraph.size.width/2.0, tickTextPosition.dy - tickParagraph.size.height/2.0));
			}
			

			canvas.drawLine(p1, p2, tickPaint);
		}
		canvas.drawArc(arcPaintOffset & arcPaintSize, startAngle, sweep, false, new ui.Paint()..color = GameColors.lowValueContent..strokeWidth = 10.0..style=PaintingStyle.stroke..strokeCap = StrokeCap.round);
		canvas.drawArc(arcPaintOffset & arcPaintSize, startAngle, sweep*value, false, new ui.Paint()..color = GameColors.highValueContent..strokeWidth = 10.0..style=PaintingStyle.stroke..strokeCap = StrokeCap.round);

		
		ui.Paint arrowPaint = new ui.Paint()..color = GameColors.midValueContent..strokeWidth = 1.0..style=PaintingStyle.stroke;
		canvas.drawParagraph(_valueParagraph, new Offset(center.dx - _valueLabelSize.width/2.0, center.dy - _valueLabelSize.height/2.0));
		canvas.save();
		canvas.translate(center.dx, center.dy - arrowPadding);
		canvas.drawPath(_arrowPath, arrowPaint);
		canvas.restore();
		canvas.save();
		
		canvas.translate(center.dx, center.dy + arrowPadding);
		canvas.scale(1.0, -1.0);
		canvas.drawPath(_arrowPath, arrowPaint);
		canvas.restore();
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