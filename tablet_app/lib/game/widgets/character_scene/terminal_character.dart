import "package:AABB/AABB.dart";
import 'package:flutter/material.dart';
import "package:nima/animation/actor_animation.dart";
import "package:nima/nima_flutter.dart";
import "package:nima/actor_node.dart";

import "terminal_scene.dart";

/// A StateMix object is used to wrap the information about an animation,
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
class TerminalCharacter
{
	FlutterActor _sourceActor;
	FlutterActor actor;
	AABB _bounds;
	ActorNode mount;
	List<StateMix> states = new List<StateMix>();
	CharacterState state = CharacterState.Happy;
	TerminalSceneRenderer scene;
    
	TerminalCharacter(this.scene, String filename)
	{
        /// Every TerminalCharacter will have three animations: Happy, Upset and Angry.
        /// They are initialized here in the constructor, and the Actor is loaded with its assets.
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
	
	void advance(double elapsed, bool animate)
	{
		if(_bounds == null)
		{
			return;
		}

		CharacterState renderState = state;
		
        for(StateMix sm in states)
		{
			if(sm.state != renderState)
			{
				sm.mix -= elapsed*TerminalSceneRenderer.mix_speed;
			}
			else
			{
				sm.mix += elapsed*TerminalSceneRenderer.mix_speed;
			}
			sm.mix = sm.mix.clamp(0.0, 1.0);
			if(sm.mix == 0.0)
			{
				sm.transitionTime = 0.0;
			}

			if(sm.mix != 0 && animate)
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

		if(mount != null)
		{
			actor.root.x = mount.x;
			actor.root.y = mount.y;
			actor.root.scaleX = mount.scaleX*0.5;
			actor.root.scaleY = mount.scaleY*0.5;
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
	}
}