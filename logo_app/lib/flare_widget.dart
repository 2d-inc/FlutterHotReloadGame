import "package:flutter/material.dart";
import "dart:ui" as ui;
import "dart:math";
import "package:flare/flare.dart" as flr;
import "package:flare/animation/actor_animation.dart";
import "dart:typed_data";

class Flare extends LeafRenderObjectWidget
{
	final String src;

	Flare(
		this.src,
		{
			Key key, 
		}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new FlareRenderObject(src);
	}

	@override
	void updateRenderObject(BuildContext context, covariant FlareRenderObject renderObject)
	{
		renderObject..src = src;
	}
}

class FlareRenderObject extends RenderBox
{
	String _src;
	flr.FlutterActor _actor;
	Float32List _aabb;

	FlareRenderObject(String src)
	{
		this.src = src;
	}

	@override
	bool get sizedByParent => false;
	
	@override
	bool hitTestSelf(Offset screenOffset) => true;

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
	//	super.performLayout();
		// if(_actor != null)
		// {
		// 	_actor.advance(0.0);
		// 	Float32List aabb = _actor.computeAABB();
		// 	_flareRect = new Rect.fromLTRB(aabb[0], aabb[1], aabb[2], aabb[3]);
		// }
	}
	
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

	String get src
	{
		return _src;
	}

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
		// actor = new FlutterActor();
		actor.loadFromBundle(value).then(
			(bool success)
			{
				_actor = actor;
				
				markNeedsLayout();
				markNeedsPaint();
				//animation = actor.getAnimation("Run");
			}
		);
	}
}
