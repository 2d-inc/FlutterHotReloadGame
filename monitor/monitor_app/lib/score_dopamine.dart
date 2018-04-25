import "package:flutter/material.dart";
import "dart:ui" as ui;
import "dart:math";
import "package:flare/flare.dart" as flr;
import "package:flare/animation/actor_animation.dart";
import "dart:typed_data";
import "package:flutter/scheduler.dart";
import "server.dart";

class ScoreDopamine extends LeafRenderObjectWidget
{
	final GameServer server;
	ScoreDopamine(
		this.server,
		{
			Key key, 
		}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new ScoreDopamineRenderObject(server);
	}

	@override
	void updateRenderObject(BuildContext context, covariant ScoreDopamineRenderObject renderObject)
	{
		renderObject..server = server;
	}
}

class ScoreDopamineRenderObject extends RenderBox
{
	GameServer _server;
	double _lastFrameTime = 0.0;

	ScoreDopamineRenderObject(GameServer server)
	{
		this.server = server;
	}

	GameServer get server
	{
		return _server;
	}

	void onScoreIncreased(int amount)
	{

	}

	set server(GameServer d)
	{
		if(_server == d)
		{
			return;
		}
		if(_server != null)
		{
			_server.onScoreIncreased = null;
		}
		_server = d;
		_server.onScoreIncreased = onScoreIncreased;
		SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
	}

	void beginFrame(Duration timeStamp) 
	{
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

		
		SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
		markNeedsPaint();
	}

	@override
	bool get sizedByParent => true;
	
	@override
	bool hitTestSelf(Offset screenOffset) => true;

	@override
	void performResize() 
	{
		size = new Size(constraints.constrainWidth(), constraints.constrainHeight());
	}

	@override
	void performLayout()
	{
		super.performLayout();
	}
	
	@override
	void paint(PaintingContext context, Offset offset)
	{
		final Canvas canvas = context.canvas;
		
		//canvas.drawRect(offset & size, new Paint()..color = const Color.fromRGBO(255, 255, 0, 0.2));
		
		
	}
}
