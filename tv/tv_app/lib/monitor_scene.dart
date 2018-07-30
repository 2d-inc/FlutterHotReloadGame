import "dart:math";
import "dart:ui" as ui;

import 'package:flutter/material.dart';
import "package:flutter/scheduler.dart";
import "package:nima/nima/actor_node.dart";
import "package:nima/nima/animation/actor_animation.dart";
import "package:nima/nima/math/vec2d.dart";
import "package:nima/nima.dart";
import "package:nima/nima/math/aabb.dart";

import "monitor_scene_character.dart";
import "monitor_widget.dart";

/// [TerminalScene] can show either one or all stakeholders on the screen.
enum MonitorSceneState
{
	All,
	BossOnly
}

typedef void SetMonitorExtentsCallback(Offset topLeft, Offset bottomRight, Offset dopamineTopLeft, Offset dopamineBottomRight);

/// All the information for the [MonitorScene], i.e. the Nima Character that animates on the left
/// side of the scren. The character will have a bouncing bubble on top of its head, displaying one of the
/// actions that the server has sent to the players. 
/// As time passes, the character gets more and more restless until the action is completed, or the
/// current task fails.
class MonitorScene extends LeafRenderObjectWidget
{
	final DateTime startTime;
	final DateTime endTime;
	final MonitorSceneState state;
	final int characterIndex;
	final String message;
	final SetMonitorExtentsCallback monitorExtentsCallback;
	final DateTime reloadDateTime;
	MonitorScene({Key key, this.state, this.characterIndex, this.message, this.startTime, this.endTime, this.monitorExtentsCallback, this.reloadDateTime}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new MonitorSceneRenderer(state, characterIndex, message, startTime, endTime, reloadDateTime)
			..monitorExtentsCallback = monitorExtentsCallback;
	}

	@override
	void updateRenderObject(BuildContext context, covariant MonitorSceneRenderer renderObject)
	{
		renderObject..state = state
					..characterIndex = characterIndex
					..message = message
					..startTime = startTime
					..endTime = endTime
					..reloadDateTime = reloadDateTime
					..monitorExtentsCallback = monitorExtentsCallback;
	}
}

/// The renderer for the Monitor Scene widget above.
/// It implements all the getters and setters needed for the widget to initialize and update 
/// correctly. Uses a scheduler to paint as smoothly as possible. 
class MonitorSceneRenderer extends RenderBox
{
    static const double MessagePadding = 40.0;
    static const double BubblePaddingH = 20.0;
    static const double BubblePaddingV = 12.0;
    
	FlutterActor _scene;
	ActorAnimation _flicker;
	double _flickerTime = 0.0;
	ActorAnimation _reload;
	double _reloadTime = 0.0;
	
	ActorAnimation _animation;
	int _characterIndex = 0;
	double _animationTime = 0.0;
	double _lastFrameTime = 0.0;
	Offset _position = new Offset(0.0, 0.0);
	double _contentHeight = 1.0;
	double _contentWidth = 1.0;
	MonitorSceneState _state;
	AABB _bounds;
	AABB _characterBounds;
	String _message;
	ui.Paragraph _messageParagraph;
	DateTime _startTime;
	DateTime _endTime;
	SetMonitorExtentsCallback monitorExtentsCallback;
	ActorNode _monitorTopLeft;
	ActorNode _monitorBottomRight;
	ActorNode _dopamineTopLeft;
	ActorNode _dopamineBottomRight;
	DateTime _reloadDateTime;

	List<MonitorCharacter> _characters = new List<MonitorCharacter>(4);
	List<MonitorCharacter> _renderCharacters = new List<MonitorCharacter>(4);

	Offset _monitorTopLeftOffset;
	Offset _monitorBottomRightOffset;
	Offset _dopamineTopLeftOffset;
	Offset _dopamineBottomRightOffset;
	
	MonitorSceneRenderer(MonitorSceneState state, int characterIndex, String message, DateTime startTime, DateTime endTime, DateTime reloadDateTime)
	{
		this.state = state;
		this.characterIndex = characterIndex;
		this.message = message;
		this.startTime = startTime;
		this.endTime = endTime;
		this.reloadDateTime = reloadDateTime;
		
        /// Start the rendering loop right after initialization
		SchedulerBinding.instance.scheduleFrameCallback(beginFrame);

        /// Build the list of characters that'll be loaded from the local assets folder.
		List<int> characterNameLookup = <int>[2,1,3,4];
		for(int i = 0; i < 4; i++)
		{
			int ci = characterNameLookup[i];
			_characters[i] = new MonitorCharacter(this, "assets/nima/NPC$ci/NPC$ci", ci);
			_renderCharacters[i] = _characters[i];
		}						

        /// Initialize the scene with a Nima Actor representing the background and 
        /// the flickering logo. 
		_scene = new FlutterActor();
		_scene.loadFromBundle("assets/nima/HotReloadScene/HotReloadScene").then((bool ok)
		{
			_scene.getAnimation("Monitor").apply(0.0, _scene, 1.0);
			_scene.advance(0.0);
			_bounds = _scene.computeAABB();

            /// Once that has been successfully loaded, all the characters can be added on top as well.
			for(int i = 0; i < 4; i++)
			{
				ActorNode mount = _scene.getNode("NPC${i+1}");
				_characters[i].focusAnimation = _scene.getAnimation("Focus${i+1}");
				if(mount is FlutterActorImage)
				{
					_characters[i].drawWith(mount);
				}
                /// A dedicated node on every [TerminalCharacter] is set 
                /// so that the [Actor] can be placed accurately.
				_characters[i].mount = mount;
                /// Set the Actor's stance to first frame of its animation loop.
				_characters[i].advance(0.0, false);
			}

            /// Calculate dimensions and evaluate the position for this [RenderBox]
			AABB bounds = _bounds;
			double height = bounds[3] - bounds[1];
			double width = bounds[2] - bounds[0];
			double x = -bounds[0] - width/2.0;
			double y =  -bounds[1] - height/2.0;
			
			_contentHeight = height;
			_contentWidth = width;
			_position = new Offset(x, y);
            
            /// Get a reference for the animations...
			_flicker = _scene.getAnimation("Flicker");
			_reload = _scene.getAnimation("Reload");

            /// ...and extract the monitor coordinates from the scene nodes that have been
            /// conveniently placed.
			_monitorTopLeft = _scene.getNode("MonitorUpperLeft");
			_monitorBottomRight = _scene.getNode("MonitorLowerRight");
			_dopamineTopLeft = _scene.getNode("DopamineUpperLeft");
			_dopamineBottomRight = _scene.getNode("DopamineLowerRight");

			markNeedsLayout();
		});
	}

	DateTime get reloadDateTime
	{
		return _reloadDateTime;
	}

	set reloadDateTime(DateTime value)
	{
		if(_reloadDateTime == value)
		{
			return;
		}
		_reloadDateTime = value;
		playReloadAnimation();
	}

	DateTime get startTime
	{
		return _startTime;
	}

	set startTime(DateTime value)
	{
		if(_startTime == value)
		{
			return;
		}
		_startTime = value;
	}

	DateTime get endTime
	{
		return _endTime;
	}

	set endTime(DateTime value)
	{
		if(_endTime == value)
		{
			return;
		}
		_endTime = value;
	}

	int get characterIndex
	{
		return _characterIndex;
	}

	set characterIndex(int index)
	{
		if(index == _characterIndex)
		{
			return;
		}
		if(_characterIndex != null && _characters[_characterIndex] != null)
		{
			_characters[_characterIndex].state = CharacterState.Happy;
		}
		_characterIndex = index;
		_bubbleOffset = null;
		
		markNeedsPaint();
		markNeedsLayout();
	}

	String get message
	{
		return _message;
	}

	set message(String value)
	{
		if(_message == value)
		{
			return;
		}
		_message = value;
		if(_message == null)
		{
			_messageParagraph = null;
			return;	
		}
        else if(value == MonitorState.backToLobbyMessage)
        {
            /// After a game has ended, reinitialize the Nima Characters.
            for(MonitorCharacter c in _characters)
            {
                c?.reinit();
            }
        }
		
		if(_characters[_characterIndex] != null)
		{
			if(_characters[_characterIndex].recomputeBounds())
			{
				_characterBounds = _characters[_characterIndex].bounds;
			}
		}
		String valueLabel = _message.toUpperCase();
		ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
			textAlign:TextAlign.start,
			fontFamily: "Inconsolata",
			fontSize: 30.0,
		))..pushStyle(new ui.TextStyle(color:const Color.fromARGB(255, 0, 92, 103)));
		builder.addText(valueLabel);
		_messageParagraph = builder.build();

		markNeedsLayout();
		markNeedsPaint();
	}

	MonitorSceneState get state
	{
		return _state;
	}

	set state(MonitorSceneState state)
	{
		if(_state == state)
		{
			return;
		}
		_state = state;
		if(_characters[_characterIndex] != null)
		{
			if(_characters[_characterIndex].recomputeBounds())
			{
				_characterBounds = _characters[_characterIndex].bounds;
			}
		}
		
		if(_scene != null)
		{
			_animation = _scene.getAnimation("Spread");
		}		

		markNeedsPaint();
		markNeedsLayout();
	}

	Offset get position
	{
		return _position;
	}

	set position(Offset offset)
	{
		if(_position == offset)
		{
			return;
		}
		_position = offset;
	}

	void playReloadAnimation()
	{
		if(_reload != null && _reloadTime > _reload.duration)
		{
			_reloadTime = 0.0;
		}
	}

	void beginFrame(Duration timeStamp) 
	{
		final double t = timeStamp.inMicroseconds / Duration.microsecondsPerMillisecond / 1000.0;
		
		if(_lastFrameTime == 0 || _bounds == null)
		{
			_lastFrameTime = t;
			SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
			// hack to circumvent not being enable to initialize lastFrameTime to a starting timeStamp (maybe it's just the date?)
			// Is the FrameCallback supposed to pass elapsed time since last frame? timeStamp seems to behave more like a date
			return;
		}

		double elapsed = t - _lastFrameTime;
		_lastFrameTime = t;
		
		MonitorCharacter boss = _characters[_characterIndex];
		
        bool focusBoss = _state != MonitorSceneState.All;
		bool recomputeBossBounds = false;
		
        /// All the [ActorAnimation]s are advanced and the new transformations are applied.
		if(_animation != null)
		{
			if(focusBoss)
			{
				_animationTime += elapsed;
			}
			else
			{
				_animationTime -= elapsed;
			}
			_animationTime = _animationTime.clamp(0.0, _animation.duration);
			_animation.apply(_animationTime, _scene, 1.0);

			if(_animationTime == _animation.duration || _animationTime == 0.0)
			{
				_animation = null;
			}
			recomputeBossBounds = true;
		}
		if(_flicker != null)
		{
			_flickerTime = (_flickerTime+elapsed)%_flicker.duration;
			_flicker.apply(_flickerTime, _scene, 1.0);
		}
		if(_reload != null)
		{
			_reloadTime += elapsed;
			_reload.apply(_reloadTime, _scene, 1.0);
		}

		for(MonitorCharacter character in _characters)
		{
			if(character.focusMix != 0.0)
			{
				character.focusAnimation.apply(character.focusTime, _scene, character.focusMix);
			}
		}
        /// Also advance the scene.
		_scene.advance(elapsed);

		DateTime now = new DateTime.now();
        /// Evaluate how much time has passed from the beginning of the current command.
        /// Characters will start getting 'Upset' when there's less than 60% of time left.
        /// Characters will start getting 'Angry' when there's less than 256% of time left.
		double f = _startTime == null ? 1.0 : 1.0-(now.difference(_startTime).inMilliseconds/_endTime.difference(_startTime).inMilliseconds).clamp(0.0, 1.0);
		if(focusBoss)
		{
			boss.state = f < 0.25 ? CharacterState.Angry : f < 0.6 ? CharacterState.Upset : CharacterState.Happy;
		}
		else
		{
			boss.state = CharacterState.Happy;
		}
		for(MonitorCharacter character in _characters)
		{
			character.advance(elapsed, character == boss);
		}
		/// Recompute bounds while spread is in action.
		if(recomputeBossBounds && _characters[_characterIndex] != null)
		{
			if(_characters[_characterIndex].recomputeBounds())
			{
				_characterBounds = _characters[_characterIndex].bounds;
			}
		}

		AABB bounds = _bounds;
		
		double height = bounds[3] - bounds[1];
		double width = bounds[2] - bounds[0];
		double x = -bounds[0] - width/2.0;
		double y =  -bounds[1] - height/2.0;
		
		double mix = min(1.0, elapsed*MonitorCharacter.MixSpeed);
		_contentHeight += (height-_contentHeight) * mix;
		_position += new Offset((x-_position.dx)*mix, (y-_position.dy)*mix);

		markNeedsPaint();
		/// Reschedule this function.
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
	void performLayout() 
	{
		super.performLayout();

        /// If a message is currently being shown, prepare the layout for it to fit within the message bubble.
		if(_messageParagraph != null)
		{
			MonitorCharacter talkCharacter = _characters[_state == MonitorSceneState.All ? 0 : _characterIndex];
			if(talkCharacter == null || talkCharacter.bounds == null)
			{
				return;
			}
			AABB b = talkCharacter.bounds;
			_messageParagraph.layout(new ui.ParagraphConstraints(width:  min(300.0, min(size.width-MessagePadding*2.0-BubblePaddingH*2.0, b[2] - b[0] + BubblePaddingH*2))));
		}
	}

	void characterLoaded(MonitorCharacter c)
	{
		MonitorCharacter talkCharacter = _characters[_state == MonitorSceneState.All ? 0 : _characterIndex];
		if(talkCharacter == c && c.recomputeBounds())
		{
			_characterBounds = c.bounds;
		}
		markNeedsLayout();
	}

	Offset _bubbleOffset;

	@override
	void paint(PaintingContext context, Offset offset)
	{
		final Canvas canvas = context.canvas;
		if(_bounds == null)
		{
			return;
		}
		//double scale = size.height/_contentHeight;
		double scale = size.width/_contentWidth;

		canvas.save();		
		canvas.clipRect(offset & size);
		canvas.translate(offset.dx + size.width/2.0, offset.dy + size.height/2.0);
		canvas.scale(scale, -scale);
		canvas.translate(_position.dx, _position.dy);
        /// First position the canvas, and then draw.
		_scene.draw(canvas);
		canvas.restore();

		_renderCharacters.sort((MonitorCharacter a, MonitorCharacter b)
		{
			return ((b.actor.root.y - a.actor.root.y) * 100.0).round();
		});

		MonitorCharacter boss = _characters[_characterIndex];
		
		for(MonitorCharacter character in _renderCharacters)
		{
			
			if(character.drawWithMount != null)
			{
				/// This character draws directly with the mount.
				continue;
			}
			canvas.save();		
			if(boss != character)
			{
				canvas.clipRect(offset & size);
			}
			canvas.translate(offset.dx + size.width/2.0, offset.dy + size.height/2.0);
			canvas.scale(scale, -scale);
			canvas.translate(_position.dx, _position.dy);

			character.draw(canvas);
			canvas.restore();
		}
		

		canvas.save();
        /// If a [_messageParagraph] String was passed to the scene, compute the bubble position and draw.
		if(_messageParagraph != null)
		{
			MonitorCharacter talkCharacter = _characters[_state == MonitorSceneState.All ? 0 : _characterIndex];
			if(talkCharacter != null)
			{
				talkCharacter.recomputeBounds();
				if(_state != MonitorSceneState.All)
				{
					AABB.combine(_characterBounds, _characterBounds, talkCharacter.bounds);
				}
			}
			
			canvas.translate(offset.dx + size.width/2.0, offset.dy + size.height/2.0);
			canvas.translate(_position.dx*scale, -_position.dy*scale);
			AABB talkBounds = talkCharacter.bounds;
			
			Offset p = new Offset((talkBounds[0]+talkBounds[2])*0.5*scale-_messageParagraph.width/2.0, -talkBounds[3]*scale - _messageParagraph.height - BubblePaddingV*4.0);
			if(_bubbleOffset == null)
			{
				_bubbleOffset = p;
			}
			_bubbleOffset += new Offset((p.dx-_bubbleOffset.dx)*0.05, (p.dy-_bubbleOffset.dy)*0.2);

			Size bubbleSize = new Size(_messageParagraph.width + BubblePaddingH*2.0, _messageParagraph.height + BubblePaddingV*2.0);
			
			Path bubble = makeBubblePath(bubbleSize.width, bubbleSize.height);
			canvas.translate(_bubbleOffset.dx + 4.0, _bubbleOffset.dy + 7.0);
			canvas.drawPath(bubble, new Paint()..color = const Color.fromARGB(48, 0, 19, 28));
			canvas.translate(-5.0, -10.0);
			canvas.drawPath(bubble, new Paint()..color = Colors.white);
			canvas.drawPath(bubble, new Paint()..color = const Color.fromARGB(255, 0, 92, 103)
													..style = PaintingStyle.stroke
													..strokeWidth = 2.0);

			canvas.drawParagraph(_messageParagraph, new Offset(BubblePaddingH, BubblePaddingV));
		}
		canvas.restore();

        /// Lastly, make adjustments for the monitor coordinates:
        /// - Evaluate them in world space, and calculate the correct offsets.
        /// - If any of them has changed, report that back to [MonitorState].
		if(_monitorTopLeft != null && _monitorBottomRight != null && _dopamineTopLeft != null && _dopamineBottomRight != null)
		{
			Vec2D topLeft = _monitorTopLeft.getWorldTranslation(new Vec2D());
			Vec2D bottomRight = _monitorBottomRight.getWorldTranslation(new Vec2D());
	
			double bx = offset.dx + size.width/2.0;
			double by = offset.dy + size.height/2.0;
			Offset monitorTopLeftOffset = new Offset(
														(_position.dx + topLeft[0])*scale+bx, 
														(_position.dy + topLeft[1])*-scale+by);
			Offset monitorBottomRightOffset = new Offset(
														(_position.dx + bottomRight[0])*scale+bx, 
														(_position.dy + bottomRight[1])*-scale+by);

			topLeft = _dopamineTopLeft.getWorldTranslation(new Vec2D());
			bottomRight = _dopamineBottomRight.getWorldTranslation(new Vec2D());
			Offset dopamineTopLeftOffset = new Offset(
														(_position.dx + topLeft[0])*scale+bx, 
														(_position.dy + topLeft[1])*-scale+by);
			Offset dopamineBottomRightOffset = new Offset(
														(_position.dx + bottomRight[0])*scale+bx, 
														(_position.dy + bottomRight[1])*-scale+by);

			if(monitorTopLeftOffset != _monitorTopLeftOffset || monitorBottomRightOffset != _monitorBottomRightOffset || dopamineTopLeftOffset != _dopamineTopLeftOffset || dopamineBottomRightOffset != _dopamineBottomRightOffset)
			{
				_monitorTopLeftOffset = monitorTopLeftOffset;
				_monitorBottomRightOffset = monitorBottomRightOffset;
				_dopamineTopLeftOffset = dopamineTopLeftOffset;
				_dopamineBottomRightOffset = dopamineBottomRightOffset;
				
				monitorExtentsCallback(_monitorTopLeftOffset, _monitorBottomRightOffset, _dopamineTopLeftOffset, _dopamineBottomRightOffset);
			}
		}

	}

	Path makeBubblePath(double width, double height)
	{
		const double arrowSize = 30.0;
		final double arrowX = width * 0.25;
		const double cornerRadius = 5.0;
		
		const double circularConstant = 0.55;
		const double icircularConstant = 1.0 - circularConstant;

		Path path = new Path();

		path.moveTo(cornerRadius, 0.0);
		path.lineTo(width-cornerRadius, 0.0);
		path.cubicTo(
						width-cornerRadius+cornerRadius*circularConstant, 0.0, 
						width, cornerRadius*icircularConstant,
						width, cornerRadius);
		path.lineTo(width, height - cornerRadius);
		path.cubicTo(
						width, height - cornerRadius + cornerRadius * circularConstant,
						width - cornerRadius * icircularConstant, height,
						width - cornerRadius, height);
		path.lineTo(arrowX+arrowSize, height);
		path.lineTo(arrowX+arrowSize/2.0, height+arrowSize/2.0);
		path.lineTo(arrowX, height);
		path.lineTo(cornerRadius, height);
		path.cubicTo(
						cornerRadius * icircularConstant, height,
						0.0, height - cornerRadius * icircularConstant,
						0.0, height - cornerRadius);
		path.lineTo(0.0, cornerRadius);

		path.cubicTo(
						0.0, cornerRadius * icircularConstant,
						cornerRadius * icircularConstant, 0.0,
						cornerRadius, 0.0);

		path.close();

		
		return path;
	}
}