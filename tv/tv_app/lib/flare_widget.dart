import "dart:typed_data";

import "package:flare/flare.dart" as flr;
import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";

/// Create a widget from a Flare asset file.
class Flare extends LeafRenderObjectWidget
{
	final String src;
	final bool isDead;
	Flare(
		this.src,
		this.isDead,
		{
			Key key, 
		}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new FlareRenderObject(src, isDead);
	}

	@override
	void updateRenderObject(BuildContext context, covariant FlareRenderObject renderObject)
	{
		renderObject..src = src
					..isDead = isDead;
	}
}

/// This [RenderBox] will draw a Flare actor directly on the canvas, and animate it as needed.
class FlareRenderObject extends RenderBox
{
	bool _isDead;
	double _animationTime = 0.0;
	double _lastFrameTime = 0.0;
	String _src;
	flr.FlutterActor _actor;
	flr.ActorAnimation _animation;
	Float32List _aabb;

	FlareRenderObject(String src, bool isDead)
	{
		this.src = src;
		this.isDead = isDead;
	}

	void beginFrame(Duration timeStamp) 
	{
		if(_animation == null)
		{
			return;
		}
		final double t = timeStamp.inMicroseconds / Duration.microsecondsPerMillisecond / 1000.0;
		
		if(_lastFrameTime == 0)
		{
			_lastFrameTime = t;
			SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
			// hack to circumvent not being enable to initialize lastFrameTime to a starting timeStamp (maybe it's just the date?)
			// Is the FrameCallback supposed to pass elapsed time since last frame? timeStamp seems to behave more like a date
			return;
		}
		
		double elapsed = (t - _lastFrameTime).clamp(0.0, 1.0);
		_lastFrameTime = t;

		_animationTime = (_animationTime + (isDead ? elapsed : -elapsed)).clamp(0.0, _animation.duration);
		_animation.apply(_animationTime, _actor, 1.0);
		_actor.advance(elapsed);
	
		if((isDead && _animationTime < _animation.duration) || (!isDead && _animationTime > 0.0))
		{
			SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
		}
		markNeedsPaint();
	}

	@override
	bool get sizedByParent => false;
	
	@override
	bool hitTestSelf(Offset screenOffset) => true;

    /// Set the actor to the beginning of its current animation, and compute its
    /// Axis-Aligned Bounding-Box.
	@override
	void performLayout()
	{
		if(_actor != null)
		{
			_actor.advance(0.0);
			_aabb = _actor.computeAABB();
			size = new Size(_aabb[2] - _aabb[0], _aabb[3] - _aabb[1]);
		}
		else
		{
			size = new Size(1.0, 1.0);
		}
	}
	
    /// The paint function will apply a translation transform, and then delegate the process 
    /// of drawing this actor to the Flare Library.
	@override
	void paint(PaintingContext context, Offset offset)
	{
		final Canvas canvas = context.canvas;
		
		if(_actor != null)
		{
			canvas.save();
			canvas.translate(offset.dx, offset.dy);
			_actor.draw(canvas);
			canvas.restore();
		}
	}

	bool get isDead => _isDead;
	String get src => _src;

    /// If this Flare Animation sets this flag, it'll try to run the "Dead Terminal" animation.
	set isDead(bool d)
	{
		if(_isDead == d)
		{
			return;
		}
		_isDead = d;
		_lastFrameTime = 0.0;
		SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
	}

    /// This is initially set by the constructor, but could also be changed by an update.
    /// It loads the corresponding source file from the bundle, and starts the render loop.
	set src(String value)
	{
		if(_src == value)
		{
			return;
		}
		_src = value;

		if(value == null)
		{
			markNeedsPaint();
			return;
		}
		flr.FlutterActor actor = new flr.FlutterActor();
		actor.loadFromBundle(value).then(
			(bool success)
			{
				_actor = actor;
				_animation = _actor.getAnimation("Dead Terminal");
				_animationTime = 0.0;
				markNeedsLayout();
				markNeedsPaint();
				SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
			}
		);
	}
}
