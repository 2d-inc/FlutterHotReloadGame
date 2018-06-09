import "dart:math";
import "dart:ui" as ui;

import "package:AABB/AABB.dart";
import 'package:flutter/material.dart';
import "package:flutter/scheduler.dart";
import "package:nima/animation/actor_animation.dart";
import "package:nima/math/mat2d.dart";
import "package:nima/nima_flutter.dart";

import "terminal_character.dart";

/// [TerminalScene] can show either one or all stakeholders on the screen.
enum TerminalSceneState
{
	All,
	BossOnly
}

/// This widget wraps the information for the [TerminalScene].
/// It displays the [FlutterActor](s) on the screen.
/// While the game is waiting for players to join or the game to begin, all the 
/// characters will be shown together on the screen with their idle animation.
/// Once the game starts, the stakeholders alternate on screen and display,
/// in a custom message bubble, the action that the game needs for this turn to complete.
class TerminalScene extends LeafRenderObjectWidget
{
    /// Every command needs to be executed within a certain timeframe.
    /// If time runs out, the current playing team loses a life.
	final DateTime startTime;
	final DateTime endTime;
	final TerminalSceneState state;
    /// There are four possible stakeholders to choose from. 
    /// For any given command, a different random character is chosen.
	final int characterIndex;
    /// The message to be shown in the bubble.
	final String message;

	TerminalScene({Key key, this.state, this.characterIndex, this.message, this.startTime, this.endTime}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new TerminalSceneRenderer(state, characterIndex, message, startTime, endTime);
	}

	@override
	void updateRenderObject(BuildContext context, covariant TerminalSceneRenderer renderObject)
	{
		renderObject..state = state
					..characterIndex = characterIndex
					..message = message
					..startTime = startTime
					..endTime = endTime;
	}
}

class TerminalSceneRenderer extends RenderBox
{
    static const double mix_speed = 5.0;
    static const double message_padding = 40.0;
    static const double bubble_padding_h = 20.0;
    static const double bubble_padding_v = 12.0;

	FlutterActor _scene;
	ActorAnimation _flicker;
	double _flickerTime = 0.0;
	ActorAnimation _animation;
	int _characterIndex = 0;
	double _animationTime = 0.0;
	double _lastFrameTime = 0.0;
	Offset _position = new Offset(0.0, 0.0);
	double _contentHeight = 1.0;
	TerminalSceneState _state;
	AABB _bounds;
	AABB _characterBounds;
	String _message;
	ui.Paragraph _messageParagraph;
	DateTime _startTime;
	DateTime _endTime;

	List<TerminalCharacter> _characters = new List<TerminalCharacter>(4);
	List<TerminalCharacter> _renderCharacters = new List<TerminalCharacter>(4);

	Color _angryBackground = Colors.transparent;
	Color _midStepGradient = Colors.transparent;
	Color _topStepGradient = Colors.transparent;
	DateTime _lastNow;
	double _colorAccumulator = 0.0;
	
	TerminalSceneRenderer(TerminalSceneState state, int characterIndex, String message, DateTime startTime, DateTime endTime)
	{
		this.state = state;
		this.characterIndex = characterIndex;
		this.message = message;
		this.startTime = startTime;
		this.endTime = endTime;
		
        /// After saving some initialization variables, start the rendering loop,
        /// by calling [beginFrame()].
		SchedulerBinding.instance.scheduleFrameCallback(beginFrame);

        /// Build the list of characters that'll be loaded from the local assets folder.
		List<int> characterNameLookup = <int>[2,1,3,4];
		for(int i = 0; i < 4; i++)
		{
			int ci = characterNameLookup[i];
			_characters[i] = new TerminalCharacter(this, "assets/nima/NPC$ci/NPC$ci");
			_renderCharacters[i] = _characters[i];
		}						

        /// Initialize the scene with a Nima Actor representing the background and 
        /// the flickering logo. 
		_scene = new FlutterActor();
		_scene.loadFromBundle("assets/nima/HotReloadScene/HotReloadScene").then((bool ok)
		{
			_scene.advance(0.0);
			_bounds = _scene.computeAABB();
            
            /// Once that has been successfully loaded, all the characters can be added on top as well.
			for(int i = 0; i < 4; i++)
			{
				_characters[i].mount = _scene.getNode("NPC${i+1}");
                /// Set the Actor's stance to first frame of its animation loop.
				_characters[i].advance(0.0, true);
            }

            /// Calculate dimensions and evaluate the position for this [RenderBox]
			AABB bounds = _bounds;
			double height = bounds[3] - bounds[1];
			double width = bounds[2] - bounds[0];
			double x = -bounds[0] - width/2.0;
			double y =  -bounds[1] - height/2.0;
			
			_contentHeight = height;
			_position = new Offset(x, y);
            /// Get a reference for the logo flickering animation.
			_flicker = _scene.getAnimation("Flicker");
			markNeedsLayout();
		});
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
		_lastNow = new DateTime.now();
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
			fontSize: 30.0
		))..pushStyle(new ui.TextStyle(color:const Color.fromARGB(255, 0, 92, 103)));
		builder.addText(valueLabel);
		_messageParagraph = builder.build();

		markNeedsLayout();
		markNeedsPaint();
	}

	TerminalSceneState get state
	{
		return _state;
	}

	set state(TerminalSceneState state)
	{
		if(_state == state)
		{
			return;
		}

		for(TerminalCharacter character in _characters)
		{
			if(character == null)
			{
				continue;
			}
			character.reinit();
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

		TerminalCharacter boss = _characters[_characterIndex];
		
        bool focusBoss = _state != TerminalSceneState.All;
		bool recomputeBossBounds = false;
		
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
            /// Increment the flickering animation time and apply for this frame.
			_flickerTime = (_flickerTime+elapsed)%_flicker.duration;
			_flicker.apply(_flickerTime, _scene, 1.0);
		}

        /// Advance the whole scene.
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
		for(TerminalCharacter character in _characters)
		{
			character.advance(elapsed, true);
		}
		/// Recompute bounds while spread is in action.
		if(recomputeBossBounds && _characters[_characterIndex] != null)
		{
			if(_characters[_characterIndex].recomputeBounds())
			{
				_characterBounds = _characters[_characterIndex].bounds;
			}
		}

		AABB bounds = focusBoss ? (_characterBounds ?? _bounds) : _bounds;
		const double PadTop = 0.35;
		const double PadBottom = 0.1;
        /// Ensure that the current character is properly positioned within its bounds and with proper padding.
        /// If a message bubble is present, the height bounds for this objects get influenced.
		if(focusBoss)
		{
			bounds = new AABB.clone(bounds);
			double realHeight = bounds[3] - bounds[1];
			bounds[3] += max(realHeight * PadTop, _messageParagraph == null ? 0.0 : _messageParagraph.height + 100.0);
			bounds[1] -= realHeight * PadBottom;
			bounds[1] = max(bounds[1], _bounds[1]);
		}
		double height = bounds[3] - bounds[1];
		double width = bounds[2] - bounds[0];
		double x = -bounds[0] - width/2.0;
		double y =  -bounds[1] - height/2.0;
		
		double mix = min(1.0, elapsed*TerminalSceneRenderer.mix_speed);
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
			TerminalCharacter talkCharacter = _characters[_state == TerminalSceneState.All ? 0 : _characterIndex];
			if(talkCharacter == null || talkCharacter.bounds == null)
			{
				return;
			}
			AABB b = talkCharacter.bounds;
			_messageParagraph.layout(
                new ui.ParagraphConstraints(
                    width: min(300.0, min(
                        size.width-TerminalSceneRenderer.message_padding*2.0-TerminalSceneRenderer.bubble_padding_h*2.0,
                        b[2] - b[0] + TerminalSceneRenderer.bubble_padding_h*2)
                    )
                )
            );
		}
	}

	void characterLoaded(TerminalCharacter c)
	{
		TerminalCharacter talkCharacter = _characters[_state == TerminalSceneState.All ? 0 : _characterIndex];
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
		double scale = size.height/_contentHeight;

		canvas.save();		
		canvas.clipRect(offset & size);
		Offset center = new Offset(offset.dx + size.width/2.0, offset.dy + size.height/2.0);
		
		canvas.translate(center.dx, center.dy);
		canvas.scale(scale, -scale);
		canvas.translate(_position.dx, _position.dy);
        /// After having properly positioned the canvas, the scene can be drawn.
		_scene.draw(canvas);
		canvas.restore();
		double fadeHeight = size.height*0.75;

		double fadeOpacity = _animation == null ? (_state == TerminalSceneState.All ? 0.0 : 1.0) : (_animationTime/_animation.duration);

		canvas.drawRect(new Offset(offset.dx, offset.dy) & new Size(size.width, fadeHeight), 
								new ui.Paint()	..shader = new ui.Gradient.linear(new Offset(0.0, offset.dy + (size.height-fadeHeight)), new Offset(0.0, offset.dy + fadeHeight), <Color>[new Color.fromARGB((100*fadeOpacity).round(), 0, 0, 0), const Color.fromARGB(0, 0, 0, 0)])
											..style = ui.PaintingStyle.fill);


		TerminalCharacter boss = _characters[_characterIndex];

        /// When there's a single character showing, the scene displays a radial gradient behind the character
        /// in order to signify how urgent the current command is.
        /// Moreover, to interpolate correctly, there's a range of gradient accumulation before the character 
        /// switches its state (Happy->Upset->Angry).
		if(boss != null && _state != TerminalSceneState.All)
		{
			DateTime now = new DateTime.now();
			double elapsed = now.difference(_lastNow).inMilliseconds / 1000.0;
			_lastNow = now;
			double f = _endTime == null ? 1.0 : (now.difference(_startTime).inMilliseconds/_endTime.difference(_startTime).inMilliseconds).clamp(0.0, 1.0);
			double fi = 1.0-f;
			double stopLerp = 0.0;

            /// "Angry State": 
            /// a three-step radial gradient accumulates from the yellowish tint, towards a more intense red color to signify the urgency of the current command.
			if(fi < 0.35 && fi > 0.0)
			{
				_colorAccumulator = 0.0;
                /// In order to perform [Color.lerp()], a normalization variable is needed.
                /// This double normalized value starts accumulating depending on how "far" the current time is from running out.
                /// The "Angry" state begins when there's only 25% of time left in the current command,
                /// and the color will start accumulating when there's 35% left, 
                /// so that there's a gradual increase towards the full gradient.
                /// Once the target has been reached, clamp the value to 1.0.
				double n = (1.0 - (fi - 0.25)/ (0.35-0.25)).clamp(0.0, 1.0);
				stopLerp = 0.27*n;
				_angryBackground = Color.lerp(Colors.transparent, new Color.fromRGBO(255, 0, 0, 0.0), n);
				_midStepGradient = Color.lerp(new Color.fromRGBO(255, 209, 0, 0.23), new Color.fromRGBO(255, 0, 0, 0.2), n);
				_topStepGradient = Color.lerp(new Color.fromRGBO(255, 179, 0, 1.0), new Color.fromRGBO(255, 0, 0, 1.0), n);
			}
            /// "Upset State": 
            /// a two-step radial gradient starts lerp-ing from the begging transparent color towards a yellowish tint.
			else if(fi < 0.75 && fi >= 0.35)
			{
				_colorAccumulator = 0.0;
                /// Same as the if statement above: normalize the range in which lerp-ing should happen.
				double n = (1.0 - (fi - 0.6)/(0.75-0.6)).clamp(0.0, 1.0);
				_midStepGradient = Color.lerp(Colors.transparent, new Color.fromRGBO(255, 209, 0, 0.23), n);
				_topStepGradient = Color.lerp(Colors.transparent, new Color.fromRGBO(255, 179, 0, 1.0) , n);
			}
            /// "Happy State": a transparent layer is displayed.
			else
			{
				_colorAccumulator = (_colorAccumulator + elapsed).clamp(0.0, 1.0);
				_angryBackground = Color.lerp(_angryBackground, Colors.transparent, _colorAccumulator);
				_midStepGradient = Color.lerp(_midStepGradient, Colors.transparent, _colorAccumulator);
				_topStepGradient = Color.lerp(_topStepGradient, Colors.transparent, _colorAccumulator);
			}

			Mat2D radialScaleMatrix = new Mat2D();
			double radialScale = size.width/size.height;
			radialScaleMatrix[0] = radialScale;
			radialScaleMatrix[4] = radialScale*size.width/2;
			canvas.drawRect(offset&size, new ui.Paint() ..color = _angryBackground);
			canvas.drawRect(offset&size, new ui.Paint() ..shader = new ui.Gradient.radial(center, size.height*1.1, [ Colors.transparent, _midStepGradient, _topStepGradient ], [0.0, 0.6 - stopLerp, 1.0], TileMode.clamp, radialScaleMatrix.mat4));
		}

        /// Sort the characters so that they're proplery drawn depending on their y coordinate.
		_renderCharacters.sort((TerminalCharacter a, TerminalCharacter b)
		{
			return ((b.actor.root.y - a.actor.root.y) * 100.0).round();
		});

		for(TerminalCharacter character in _renderCharacters)
		{
			canvas.save();		
			if(boss != character)
			{
				canvas.clipRect(offset & size);
			}
			canvas.translate(offset.dx + size.width/2.0, offset.dy + size.height/2.0);
			canvas.scale(scale, -scale);
			canvas.translate(_position.dx, _position.dy);

            /// Draw all the characters on top of the scene.
			character.draw(canvas);
			canvas.restore();
		}		

		canvas.save();

        /// Once a String message is passed to the scene, compute the bubble position and draw.
		if(_messageParagraph != null)
		{
			TerminalCharacter talkCharacter = _characters[_state == TerminalSceneState.All ? 0 : _characterIndex];
			if(talkCharacter != null)
			{
				talkCharacter.recomputeBounds();
				if(_state != TerminalSceneState.All)
				{
					AABB.combine(_characterBounds, _characterBounds, talkCharacter.bounds);
				}
			}
			
			canvas.translate(offset.dx + size.width/2.0, offset.dy + size.height/2.0);
			canvas.translate(_position.dx*scale, -_position.dy*scale);
			AABB talkBounds = talkCharacter.bounds;
			
			Offset p = new Offset((talkBounds[0]+talkBounds[2])*0.5*scale-_messageParagraph.width/2.0, -talkBounds[3]*scale - _messageParagraph.height - TerminalSceneRenderer.bubble_padding_v*4.0);
			if(_bubbleOffset == null)
			{
				_bubbleOffset = p;
			}
			_bubbleOffset += new Offset((p.dx-_bubbleOffset.dx)*0.05, (p.dy-_bubbleOffset.dy)*0.2);

			Size bubbleSize = new Size(_messageParagraph.width + TerminalSceneRenderer.bubble_padding_h*2.0, _messageParagraph.height + TerminalSceneRenderer.bubble_padding_v*2.0);
			
			Path bubble = makeBubblePath(bubbleSize.width, bubbleSize.height);
			canvas.translate(_bubbleOffset.dx + 4.0, _bubbleOffset.dy + 7.0);
			canvas.drawPath(bubble, new Paint()..color = const Color.fromARGB(48, 0, 19, 28));
			canvas.translate(-5.0, -10.0);
			canvas.drawPath(bubble, new Paint()..color = Colors.white);
			canvas.drawPath(bubble, new Paint()..color = const Color.fromARGB(255, 0, 92, 103)
													..style = PaintingStyle.stroke
													..strokeWidth = 2.0);

			canvas.drawParagraph(_messageParagraph, new Offset(TerminalSceneRenderer.bubble_padding_h, TerminalSceneRenderer.bubble_padding_v));
		}
		canvas.restore();
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