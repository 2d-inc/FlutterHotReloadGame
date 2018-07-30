import "package:AABB/AABB.dart";
import 'package:flutter/material.dart';
import "package:nima/actor_node.dart";
import "package:nima/animation/actor_animation.dart";
import "package:nima/nima_flutter.dart";

import "monitor_scene.dart";

/// Wrap the information about an animation,
/// and the transition that happens when the character needs to interpolate from the current one to the next.
class StateMix
{
	CharacterState state;
	ActorAnimation animation;
	ActorAnimation transitionAnimation;

	double animationTime;
	double transitionTime;
	double mix;
}

enum CharacterState
{
	Happy,
	Upset,
	Angry
}

/// Wraps a [FlutterActor] from the Nima runtime library in order to build the stakeholders'
/// animations. Every Character will have three animations: Happy, Upset and Angry.
/// They are initialized in the constructor, and the Actor is loaded with its assets.
class MonitorCharacter
{
    static const double MixSpeed = 5.0;

	FlutterActor _sourceActor;
	FlutterActor actor;
	AABB _bounds;
	ActorNode mount;
	FlutterActorImage drawWithMount;
	List<StateMix> states = new List<StateMix>();
	CharacterState state = CharacterState.Happy;
	MonitorSceneRenderer scene;

	ActorAnimation focusAnimation;
	double focusTime = 0.0;
	double focusMix = 0.0;
	int idx;

	MonitorCharacter(this.scene, String filename, this.idx)
	{
		states.add(new StateMix()
									..state = CharacterState.Happy
									..mix = 1.0
									..animationTime = 0.0);

		states.add(new StateMix()
									..state = CharacterState.Upset
									..mix = 0.0
									..animationTime = 0.0);

		states.add(new StateMix()
									..state = CharacterState.Angry
									..mix = 0.0
									..animationTime = 0.0);

		load(filename);
	}

	void drawWith(FlutterActorImage image)
	{
		drawWithMount = image;
		drawWithMount.onDraw = this.draw;
	}

	AABB get bounds
	{
		return _bounds;
	}

	bool recomputeBounds()
	{
		if(_bounds != null) // only do this if bounds has already been computed
		{
			_bounds = actor.computeAABB();
			return true;
		}
		return false;
	}

	ActorAnimation getAnimation(CharacterState state)
	{
		String animationName;
		switch(state)
		{
			case CharacterState.Happy:
				animationName = "Happy";
				break;
			case CharacterState.Angry:
				animationName = "Angry";
				break;
			case CharacterState.Upset:
				animationName = "Upset";
				break;
		}
		return actor.getAnimation(animationName);
	}

    /// These intermediate animations are used to smoothly transition from one state to the next.
	ActorAnimation getTransitionAnimation(CharacterState state)
	{
		String animationName;
		switch(state)
		{
			case CharacterState.Happy:
				animationName = null;
				break;
			case CharacterState.Angry:
				animationName = "Upset-Angry";
				break;
			case CharacterState.Upset:
				animationName = "Happy-Upset";
				break;
		}
		return animationName == null ? null : actor.getAnimation(animationName);
	}

    /// Load the resources from storage, and make the actor instance.
	void load(String filename)
	{
		_sourceActor = new FlutterActor();
		_sourceActor.loadFromBundle(filename).then((bool ok)
		{
            actor = _sourceActor.makeInstance();
			for(StateMix sm in states)
			{
				sm.animation = getAnimation(sm.state);
				sm.transitionAnimation = getTransitionAnimation(sm.state);
				sm.transitionTime = 0.0;
				if(sm.animation != null && sm.state == CharacterState.Happy)
				{
					sm.animationTime = 0.0;
					sm.animation.apply(sm.animationTime, actor, 1.0);
				}
			}
			actor.advance(0.0);
			_bounds = actor.computeAABB();
			this.scene.characterLoaded(this);
		});
	}

	/// Advance the animation by the [elapsed] time value.
	void advance(double elapsed, bool isBoss)
	{
		if(_bounds == null)
		{
			return;
		}

		CharacterState renderState = state;
		if(focusAnimation != null)
		{
			focusTime = (focusTime + ((isBoss ? 1 : -1) * elapsed)).clamp(0.0, focusAnimation.duration);
			focusMix = (focusMix + ((isBoss ? 1 : -1) * elapsed * 2.0)).clamp(0.0, 1.0);
		}
		for(StateMix sm in states)
		{
			if(sm.state != renderState)
			{
				sm.mix -= elapsed*MixSpeed;
			}
			else
			{
				sm.mix += elapsed*MixSpeed;
			}
			sm.mix = sm.mix.clamp(0.0, 1.0);
			if(sm.mix == 0.0)
			{
				sm.transitionTime = 0.0;
			}

			if(sm.mix != 0)
			{ 
				if(sm.transitionAnimation == null || sm.transitionTime >= sm.transitionAnimation.duration)
				{
					sm.animationTime = (sm.animationTime+elapsed) % sm.animation.duration;
					sm.animation.apply(sm.animationTime, actor, sm.mix);
				}
				else
				{
					sm.transitionTime = sm.transitionTime+elapsed;
					sm.transitionAnimation.apply(sm.transitionTime, actor, sm.mix);
				}
			}
		}

        /// Translate and scale the actor.
		if(mount != null)
		{
			actor.root.x = mount.x;
			actor.root.y = mount.y;
			actor.root.scaleX = mount.scaleX*0.65;
			actor.root.scaleY = mount.scaleY*0.65;
		}
		actor.advance(elapsed);
	}

	void draw(Canvas canvas)
	{
		if(_bounds == null)
		{
			return;
		}
		actor.draw(canvas);
	}

    void reinit()
    {
        actor = _sourceActor.makeInstance();
        advance(0.0, true);
        print("REINIT!");
    }
}