import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import "package:nima/animation/actor_animation.dart";
import "package:nima/nima_flutter.dart";

class NimaWidget extends LeafRenderObjectWidget
{
	final String _filename;

	NimaWidget(this._filename, {Key key}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new NimaRenderObject(_filename);
	}

	@override
	void updateRenderObject(BuildContext context, covariant NimaRenderObject renderObject)
	{
		renderObject.filename = _filename;
	}
}

class NimaRenderObject extends RenderBox
{
	String filename;
	String _loadedFilename;//
	FlutterActor _actor;
	FlutterActor _actorInstance;
	ActorAnimation _animation;
	double _animationTime;
	double _lastFrameTime = 0.0;
	
	//final AnimationController controller = new AnimationController(duration: const Duration(milliseconds: 500), vsync: this);

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

		double elapsed = t - _lastFrameTime;
		_lastFrameTime = t;
		//print("ELAPSED $elapsed");
		
		if(_actorInstance != null)
		{
			_animationTime += elapsed;
			if(_animation != null)
			{
				_animation.apply(_animationTime%2.0, _actorInstance, 1.0);
			}
			_actorInstance.advance(elapsed);
		}

		markNeedsPaint();
		//SchedulerBinding.instance.scheduleFrame();
		SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
	}

	NimaRenderObject(this.filename)
	{
		//Ticker ticker = new Ticker(this.onTick);
		//SchedulerBinding.instance.addPersistentFrameCallback(beginFrame);
		SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
	}

	@override
	bool get sizedByParent => true;
	
	@override
	bool hitTestSelf(Offset screenOffset) => true;

	@override
	void performResize() 
	{
		size = constraints.biggest;
	}

	@override
	void paint(PaintingContext context, Offset offset)
	{
		//print("Paint Nima");
		final Canvas canvas = context.canvas;
		if(_actorInstance == null)
		{
			return;
		}
		canvas.save();
		canvas.scale(0.80, -0.80);
		canvas.translate(410.0, -1250.0);
		//_actorInstance.advance(0.0);
		_actorInstance.draw(canvas);
		canvas.restore();
	}

	@override
	markNeedsPaint()
	{
		if(_loadedFilename != filename)
		{
			_actor = new FlutterActor();
			_loadedFilename = filename;
			_actor.loadFromBundle(filename).then((ok)
			{
				_actorInstance = _actor;//.makeInstance();
				_animation = _actor.getAnimation("Angry");
				_animationTime = 0.0;
				markNeedsPaint();
			});
		}
		super.markNeedsPaint();
	}
}
