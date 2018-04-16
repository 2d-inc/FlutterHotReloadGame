import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'sound.dart';
import 'flutter_task.dart';
import 'dart:async';
import 'dart:math';
import "dart:io";
import "dart:convert";
import 'sound.dart';
import 'flutter_task.dart';
import "text_render_object.dart";
import "package:nima/nima_flutter.dart";
import "package:nima/animation/actor_animation.dart";
import "package:flutter/animation.dart";
import "dart:ui" as ui;
import "package:flutter/scheduler.dart";
import "server.dart";

const double BACKGROUND_SCREEN_WIDTH = 1052.0;
const double BACKGROUND_SCREEN_HEIGHT = 566.0;
const double BACKGROUND_MARGIN_LEFT = 721.0;
const double BACKGROUND_MARGIN_TOP = 200.0;

Future<String> loadFileAssets(String filename) async
{
	return await rootBundle.loadString("assets/files/$filename");
}

class CodeBoxWidget extends LeafRenderObjectWidget
{
	final String _contents;
	final double _lineNumber;
	final Highlight _highlight;
	final int _alpha;

	CodeBoxWidget(
		this._contents, 
		this._lineNumber,
		this._highlight,
		this._alpha,
		{Key key}) : super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context)
	{
		var ro = new TextRenderObject()
			..text = this._contents
			..scrollValue = _lineNumber
			..highlight = this._highlight
			..highlightAlpha = this._alpha;

		return ro;
	}

	@override
	void updateRenderObject(BuildContext context, TextRenderObject renderObject) 
	{
		renderObject
			..text = this._contents
			..scrollValue = _lineNumber
			..highlight = this._highlight
			..highlightAlpha = this._alpha;
	}
}

class CodeBox extends StatefulWidget
{
	final String title;
	
	CodeBox({Key key, this.title}) : super(key:key);

	@override
	CodeBoxState createState() => new CodeBoxState();
}

class CodeBoxState extends State<CodeBox> with TickerProviderStateMixin
{
	static const int HIGHLIGHT_ALPHA_FULL = 150;
	static const int MAX_FLICKER_COUNT = 6;

	double _lineOfInterest = 0.0;
	Highlight _highlight;
	bool _upFacing = false;
	List<Sound> _sounds;
	FlutterTask _flutterTask = new FlutterTask("~/Projects/BiggerLogo/logo_app");
	GameServer _server;
	Random _rng = new Random();
	bool _ready = false;
	String _contents;
	bool _isReloading;

	AnimationController _scrollController;
	AnimationController _highlightController;
	int _flickerCounter = 0;
	int _highlightAlpha = HIGHLIGHT_ALPHA_FULL;
	Animation<double> _scrollAnimation;
	Animation<double> _highlightAnimation;
	AnimationStatusListener _scrollStatusListener;

	@override
	initState()
	{
		super.initState();
		_scrollController = new AnimationController(duration: const Duration(milliseconds: 350), vsync: this)
			..addListener(
				() {
					setState(() 
					{
						_lineOfInterest = _scrollAnimation.value;
					});
				}		
		);

		_highlightController = new AnimationController(vsync: this, duration: new Duration(milliseconds: 100))
			..addListener(
				()
				{
					setState(
						()
						{
							this._highlightAlpha = _highlightAnimation.value.toInt();
							// Stop the animation ELSE flicker
							if(_flickerCounter == MAX_FLICKER_COUNT)
							{
								_flickerCounter = 0;
								_highlightController.stop();
							}
							else if(_highlightAnimation.status == AnimationStatus.completed)
							{
								_highlightController.reverse();
								_flickerCounter++;
							}
							else if(_highlightAnimation.status == AnimationStatus.dismissed)
							{
								_highlightController.forward();
								_flickerCounter++;
							}
						}
					);
				}
			);
		_scrollStatusListener = 
		(AnimationStatus state)
		{
			if(state == AnimationStatus.completed)
			{
				_scrollAnimation?.removeStatusListener(_scrollStatusListener);
				setState(
					()
					{
						_highlightAnimation = new Tween<double>(
							begin: HIGHLIGHT_ALPHA_FULL.toDouble(),
							end: 0.0
						).animate(_highlightController);
						_highlightController..forward();
					}
				);
			}
		};
	}

	@override
	dispose()
	{
		_scrollController.dispose();
		_highlightController.dispose();
		super.dispose();
	}

	CodeBoxState() :
		_highlight = new Highlight(0, 0, 0)
	{
		_flutterTask.onReady(()
		{
			setState(() 
			{
				_ready = true;
			});
		});

		// Read contents.
		_flutterTask.read("/main_template.dart").then((contents)
		{
			_contents = contents;
			if(_contents != null)
			{
				_contents = _contents.replaceAll("FeaturedRestaurantAligned", "FeaturedRestaurantSimple");
				_contents = _contents.replaceAll("CategoryAligned", "CategorySimple");
				_contents = _contents.replaceAll("RestaurantsHeaderAligned", "RestaurantsHeaderSimple");
				_contents = _contents.replaceAll("RestaurantAligned", "RestaurantSimple");
			}

			_flutterTask.write("/lib/main.dart", _contents).then((ok)
			{
				// Start emulator.
				_flutterTask.load('"iPhone 8"').then((success)
				{
					_server = new GameServer(_flutterTask, _contents);
					_server.onUpdateCode = (String code, int lineOfInterest)
					{
						setState(()
						{
							_contents = code; 
							_highlight = new Highlight(lineOfInterest, 0, 1);
							_scrollAnimation = new Tween<double>(
								begin: _lineOfInterest,
								end: lineOfInterest.toDouble()

							).animate(_scrollController)
								..addStatusListener(_scrollStatusListener);

							_scrollController
								..value = 0.0
								..animateTo(1.0, curve: Curves.easeInOut);
						});
					};
				});
			});
		});
		
		_sounds = new List<Sound>();
		for(int i = 1; i <= 5; i++)
		{
			Sound sound = new Sound();
			sound.load("/assets/button" + i.toString() + ".mp3");
			_sounds.add(sound); 
		}
	}

	@override
	Widget build(BuildContext context)
	{
		Size sz = MediaQuery.of(context).size;

		Stack stack = new Stack(
					children: [
						new Container(
							color: const Color.fromARGB(255, 0, 0, 0),
							width: sz.width,
							height: sz.height,
							child: new Stack(
										children: 
										[
											new Image.asset(
												"/assets/images/tv_background.png",
												bundle: rootBundle,
												width: sz.width,
												height: sz.height
											),
											// new NimaWidget("/assets/nima/NPC1/NPC1")
										]
									)
						),
						new Positioned(
							left: BACKGROUND_MARGIN_LEFT,// - 500, /* TODO: remove extra margin only for simulator*/
							top: BACKGROUND_MARGIN_TOP,
							width: BACKGROUND_SCREEN_WIDTH,
							height: BACKGROUND_SCREEN_HEIGHT,
							child: new CodeBoxWidget(
									_contents, 
									_lineOfInterest, 
									_highlight, 
									_highlightAlpha
								)
						)
						],
			);

		return new Scaffold(
			body: new Center(child: stack)
		);
	}
}

class MonitorApp extends StatelessWidget
{
	@override
	Widget build(BuildContext context)
	{
		return new MaterialApp(
			home: new CodeBox(),
		);
	}
}

void main()
{
	runApp(new MonitorApp());
}

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
