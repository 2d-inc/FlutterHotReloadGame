import "dart:math";
import "dart:ui" as ui;

import "package:flutter/material.dart";

import "../game/game_provider.dart";
import "game_colors.dart";
import "game_command_widget.dart";
import "game_radial.dart";

class GameSliderNotched extends StatefulWidget implements GameCommand
{
	GameSliderNotched.make(this.taskType, Map params) : value = params['min'], min = params['min'], max = params['max'];

	GameSliderNotched.fromRadial(GameRadial radial) :
		taskType = radial.taskType,
		value = radial.value, min = radial.min, max = radial.max;

	final int value;
	final int min;
	final int max;
	final String taskType;

	@override
	_GameSliderNotchedState createState() => new _GameSliderNotchedState(value, min, max);
}

class _GameSliderNotchedState extends State<GameSliderNotched> with TickerProviderStateMixin
{
	_GameSliderNotchedState(this.value, this.minValue, this.maxValue);

	final int minValue;
	final int maxValue;
	
	AnimationController _controller;
	AnimationController _highlightController;
	Animation<double> _valueAnimation;
	Animation<double> _highlightValueAnimation;

	int value = 0;
	int targetValue = 0;

	int highlightValue = 0;
	int targetHighlightValue = 0;
	
	void valueChanged(double v)
	{
		int targetHighlight = (minValue + (v * 4).floor() * ((maxValue-minValue)/4)).floor();
		int target = (minValue + v * (maxValue-minValue)).ceil();
		if(targetValue != target)
		{
			targetValue = target;
			_valueAnimation = new Tween<double>
			(
				begin: value.toDouble(),
				end: targetValue.toDouble()
			).animate(_controller);
		
			_controller
				..value = 0.0
				..animateTo(1.0, curve:Curves.linear);
		}
		if(targetHighlightValue != targetHighlight)
		{
			targetHighlightValue = targetHighlight;
			targetHighlightValue = targetHighlight;
			_highlightValueAnimation = new Tween<double>
			(
				begin: highlightValue.toDouble(),
				end: targetHighlightValue.toDouble()
			).animate(_highlightController);
		
			_highlightController
				..value = 0.0
				..animateTo(1.0, curve:Curves.linear);
		}

	}

	void commitValueChange(BuildContext context)
	{
		if(targetValue != targetHighlightValue)
		{
			targetValue = targetHighlightValue;
			_valueAnimation = new Tween<double>
			(
				begin: value.toDouble(),
				end: targetValue.toDouble()
			).animate(_controller);
		
			_controller
				..value = 0.0
				..animateTo(1.0, curve:Curves.linear);
		}
		GameProvider.of(context).issueCommand(widget.taskType, targetHighlightValue);
	}

	@override
	dispose()
	{
		_controller.dispose();
		_highlightController.dispose();
		super.dispose();
	}

	initState() 
	{
    	super.initState();
		_controller = new AnimationController(duration: const Duration(milliseconds: 100), vsync: this);
		_highlightController = new AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
		_highlightController.addListener(()
		{
			setState(
				()
				{
					highlightValue = _highlightValueAnimation.value.round();
				}
			);
		});
		_controller.addListener(()
		{
			setState(()
			{
				value = _valueAnimation.value.round();
			});
		});
	}

	@override
	Widget build(BuildContext context) 
	{
		return new Container(
			child:new Column(
				mainAxisAlignment: MainAxisAlignment.center,
				children: <Widget>[
					new Container(
						// margin:
						child:new Text(highlightValue.toString(), 
							style: const TextStyle(color: GameColors.white,
								fontFamily: "Inconsolata", 
								fontWeight: FontWeight.w700, 
								fontSize: 36.0, 
								decoration: TextDecoration.none
							)
						)
					),
					new Container(
						margin: const EdgeInsets.symmetric(vertical: 20.0),
						child: new Row(children:<Widget>[
							new Container(
								margin: new EdgeInsets.only(right: 10.0), 
								child: new Text(
									minValue.toString(), 
									style: const TextStyle(color: GameColors.highValueContent, 
									fontFamily: "Inconsolata", 
									fontWeight: FontWeight.w700, 
									fontSize: 16.0, 
									decoration: TextDecoration.none)
								)
							),
							new Expanded(child: new NotchedSlider((value-minValue)/(maxValue-minValue), (highlightValue-minValue)/(maxValue-minValue), valueChanged, () => commitValueChange(context))),
							new Container(
								margin: new EdgeInsets.only(left: 10.0), 
								child:new Text(maxValue.toString(), 
									style: const TextStyle(color: GameColors.highValueContent, 
									fontFamily: "Inconsolata", 
									fontWeight: FontWeight.w700, 
									fontSize: 16.0, 
									decoration: TextDecoration.none)
								)
							),
						])
					)
				]
			)
		);
	}
}

typedef void ValueChangeCallback(double value);

class NotchedSlider extends StatefulWidget 
{
	NotchedSlider(this.value, this.targetValue, this.valueChanged, this.commitValue, {Key key}) : super(key: key);

	final double value;
	final double targetValue;
	final ValueChangeCallback valueChanged;
	final VoidCallback commitValue;

	@override
	_NotchedSliderState createState() => new _NotchedSliderState();
}

class _NotchedSliderState extends State<NotchedSlider>
{
	_NotchedSliderState();

	void dragStart(DragStartDetails details)
	{
		RenderBox ro = context.findRenderObject();
		if(ro == null)
		{
			return;
		}
		if(ro == null)
		{
			return;
		}
		Offset local = ro.globalToLocal(details.globalPosition);
		widget.valueChanged(min(1.0, max(0.0, local.dx/context.size.width)));
	}

	void dragUpdate(DragUpdateDetails details)
	{
		RenderBox ro = context.findRenderObject();
		if(ro == null)
		{
			return;
		}
		Offset local = ro.globalToLocal(details.globalPosition);
		widget.valueChanged(min(1.0, max(0.0, local.dx/context.size.width)));
	}

	void dragEnd(DragEndDetails details)
	{
		widget.commitValue();
	}
	
	@override
	Widget build(BuildContext context) 
	{
		return new GestureDetector(
			onHorizontalDragStart: dragStart,
			onHorizontalDragUpdate: dragUpdate,
			onHorizontalDragEnd: dragEnd,
			child: new Container(
				child:new GameSliderNotches(widget.value, widget.targetValue)
			)
		);
	}
}

class GameSliderNotches extends LeafRenderObjectWidget
{
	final double value;
	final double targetValue;

	GameSliderNotches(this.value, this.targetValue,
		{
			Key key
		}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new GameSliderNotchesRenderObject(value, targetValue);
	}

	@override
	void updateRenderObject(BuildContext context, covariant GameSliderNotchesRenderObject renderObject)
	{
		renderObject
			..value = value
			..targetValue = targetValue;
	}
}

class GameSliderNotchesRenderObject extends RenderBox
{
	double _value;
	double _targetValue;

	GameSliderNotchesRenderObject(double value, double targetValue)
	{
		this.value = value;
		this.targetValue = targetValue;
	}

	@override
	bool get sizedByParent => true;
	
	@override
	bool hitTestSelf(Offset screenOffset) => true;

	@override
	void performResize() 
	{
		size = new Size(constraints.constrainWidth(), 30.0);
	}

	@override
	void paint(PaintingContext context, Offset offset)
	{
		final Canvas canvas = context.canvas;
		const double notchWidth = 10.0;
		const double notchIdealPadding = 10.0;
		int numNotches = (size.width / (notchWidth+notchIdealPadding)).floor();
		double spacing = (size.width - numNotches*notchWidth)/max(1, (numNotches-1));

		double dx = 0.0;
		Size notchSize = new Size(notchWidth, size.height);
		int notchesHighlit = (value * numNotches).round();
		int targetHighlight = (targetValue * numNotches).round();

		for(int i = 0; i < notchesHighlit; i++)
		{
			final RRect rrect = new RRect.fromRectAndRadius(new Offset(offset.dx+dx, offset.dy) & notchSize, const Radius.circular(2.0));
			canvas.drawRRect(rrect, new ui.Paint()..color = GameColors.highValueContent);
			dx += notchWidth + spacing;
		}

		for(int i = notchesHighlit + 1; i <= numNotches; i++)
		{
    		final RRect rrect = new RRect.fromRectAndRadius(new Offset(offset.dx+dx, offset.dy) & notchSize, const Radius.circular(2.0));
			canvas.drawRRect(rrect, new ui.Paint()..color = GameColors.lowValueContent);
			dx += notchWidth + spacing;
		}

		if(targetHighlight != 0)
		{
			dx = (notchWidth + spacing) * (targetHighlight-1);
			int extraSpace = 8;
			Size selectedSize = new Size(notchSize.width + extraSpace, notchSize.height + extraSpace);
			final RRect selectedNotch = new RRect.fromRectAndRadius(new Offset(offset.dx+dx - extraSpace/2, offset.dy - extraSpace/2) & selectedSize, const Radius.circular(6.0));
			canvas.drawRRect(selectedNotch, new ui.Paint()..color = GameColors.white..style = PaintingStyle.stroke..strokeWidth = 2.0);
		}

	}

	double get value
	{
		return _value;
	}

	double get targetValue => _targetValue;

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

	set targetValue(double v)
	{
		if(_targetValue == v)
		{
			return;
		}
		_targetValue = v;

		markNeedsLayout();
		markNeedsPaint();
	}
}