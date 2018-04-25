import 'dart:collection';
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
import "monitor_scene.dart";
import "tasks/command_tasks.dart";
import "stdout_display.dart";
import "flare_widget.dart";
import "shadow_text.dart";
import "score.dart";
import "high_scores_screen.dart";
import "high_scores.dart";

const double STDOUT_PADDING = 41.0;
const double STDOUT_HEIGHT = 150.0 - STDOUT_PADDING;
const int STDOUT_MAX_LINES = 5;
const String targetDevice = '"iPhone 8"';
const String logoAppLocation = "~/Projects/BiggerLogo/logo_app";

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
	static const int HIGHLIGHT_ALPHA_FULL = 56;
	static const int MAX_FLICKER_COUNT = 6;

	double _lineOfInterest = 0.0;
	Highlight _highlight;
	List<Sound> _sounds;
	FlutterTask _flutterTask;
	GameServer _server;
	bool _ready = false;
	bool _allowReinit = false;
	String _contents;
	ListQueue<String> _stdoutQueue;
	IssuedTask _currentDisplayTask;

	AnimationController _scrollController;
	AnimationController _highlightController;
	int _flickerCounter = 0;
	int _highlightAlpha = HIGHLIGHT_ALPHA_FULL;
	Animation<double> _scrollAnimation;
	Animation<double> _highlightAnimation;
	AnimationStatusListener _scrollStatusListener;

	Offset _monitorTopLeft;
	Offset _monitorBottomRight;
	DateTime _startTaskTime;
	DateTime _failTaskTime;
	DateTime _waitMessageTime;
	int _characterIndex = 0;
	int _lives = 0;
	int _score = 0;
	String _characterMessage;
	bool _showHighScores = true;
	HighScore _highScore;
	DateTime _reloadTime;

	void showLobby()
	{
		_characterIndex = 0;
		_characterMessage = "WAITING FOR 2-4 PLAYERS!";
		_startTaskTime = null;
		_failTaskTime = null;
		_showHighScores = true;
		_highScore = null;
	}

	@override
	initState()
	{
		super.initState();

		showLobby();

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

	initFlutterTask()
	{
		_ready = false;
		_allowReinit = false;
		if(_flutterTask != null)
		{
			_flutterTask.onReady(null);
			_flutterTask.onStdout(null);
			_flutterTask.terminate();
		}
		_flutterTask = new FlutterTask(logoAppLocation);
		_flutterTask.onReady(()
		{
			setState(() 
			{
				_ready = true;
			});
		});
		_flutterTask.onStdout((String line)
		{
			setState(()
				{
					while(_stdoutQueue.length > STDOUT_MAX_LINES - 1)
					{
						_stdoutQueue.removeFirst();
					}
					_stdoutQueue.addLast(line);
				}
			);
		});
	}

	CodeBoxState() :
		_highlight = new Highlight(-1, 0, 0)
	{
		initFlutterTask();

		_stdoutQueue = new ListQueue<String>(STDOUT_MAX_LINES);
		// Read contents.
		_flutterTask.read("/lib/main_template.dart").then((contents)
		{
			_contents = contents;

			_flutterTask.write("/lib/main.dart", _contents).then((ok)
			{
				// Start emulator.
				_flutterTask.load(targetDevice).then((success)
				{
					_allowReinit = true;
					_server = new GameServer(_flutterTask, _contents);
					
					_server.onLivesUpdated = ()
					{
						setState(()
						{
							_lives = _server.lives;
						});
					};

					_server.onScoreChanged = ()
					{
						setState(()
						{
							_score = _server.score;
						});
					};

					_server.onUpdateCode = (String code, int lineOfInterest)
					{
						_reloadTime = new DateTime.now();
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

					_server.onTaskIssued = (IssuedTask task, DateTime failTime)
					{
						if((_failTaskTime == null || new DateTime.now().isAfter(_failTaskTime)) && (_waitMessageTime == null || new DateTime.now().isAfter(_waitMessageTime)))
						{
							setState(()
							{
								_characterIndex = new Random().nextInt(4);
								_characterMessage = task.task.getIssueCommand(task.value);
								_startTaskTime = new DateTime.now();
								_currentDisplayTask = task;
								_failTaskTime = failTime;
							});
						}
					};

					_server.onTaskCompleted = (IssuedTask task, DateTime failTime, String message)
					{
						if(_currentDisplayTask == task)
						{
							setState(()
							{
								_characterMessage = message;
								_startTaskTime = null;
								_currentDisplayTask = task;
								_failTaskTime = null;
								_waitMessageTime = new DateTime.now().add(const Duration(seconds: 2));
							});
						}
					};

					_server.onGameStarted = ()
					{
						setState(()
						{
							_showHighScores = false;
						});
					};

					_server.onGameOver = ()
					{
						setState(()
						{
							showLobby();
							_highScore = _server.highScore;
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

		final bool hasMonitorCoordinates = _monitorTopLeft != null && _monitorBottomRight != null;

		final double CODE_BOX_SCREEN_WIDTH = hasMonitorCoordinates ? _monitorBottomRight.dx - _monitorTopLeft.dx : 0.0;
		final double CODE_BOX_SCREEN_HEIGHT = hasMonitorCoordinates ? _monitorBottomRight.dy - _monitorTopLeft.dy : 0.0;
		final double CODE_BOX_MARGIN_LEFT = hasMonitorCoordinates ? _monitorTopLeft.dx : 0.0;
		final double CODE_BOX_MARGIN_TOP = hasMonitorCoordinates ? _monitorTopLeft.dy : 0.0;

		Stack stack = new Stack(
					children: 
					[
						new Container(
							color: const Color.fromARGB(255, 0, 0, 0),
							width: sz.width,
							height: sz.height,
							child: new Stack(
										children: 
										[
											new MonitorScene(state:MonitorSceneState.BossOnly, reloadDateTime:_reloadTime, characterIndex: _characterIndex, message:_characterMessage, startTime: _startTaskTime, endTime:_failTaskTime, monitorExtentsCallback:(Offset topLeft, Offset bottomRight)
											{
												if(_monitorTopLeft != topLeft || _monitorBottomRight != bottomRight)
												{
													setState(() 
													{
														_monitorTopLeft = topLeft;
														_monitorBottomRight = bottomRight;
													});
												}	
											})
										]
									)
						),
						new Container(margin:const EdgeInsets.only(left:50.0, top:20.0, right:50.0), 
							child: new Row
							(
								children:<Widget>
								[
									new Column
									(
										crossAxisAlignment: CrossAxisAlignment.start,
										children:<Widget>
										[
											new Container(margin:const EdgeInsets.only(bottom:7.0), child:ShadowText("LIVES", spacing: 5.0, fontFamily: "Roboto", fontSize: 19.0)),
											new Row
											(
												children: <Widget>
												[
													new Container(margin:const EdgeInsets.only(right:10.0), child:new Flare("assets/flares/Heart", _lives < 1)),
													new Container(margin:const EdgeInsets.only(right:10.0), child:new Flare("assets/flares/Heart", _lives < 2)),
													new Container(margin:const EdgeInsets.only(right:10.0), child:new Flare("assets/flares/Heart", _lives < 3)),
													new Container(margin:const EdgeInsets.only(right:10.0), child:new Flare("assets/flares/Heart", _lives < 4)),
													new Container(margin:const EdgeInsets.only(right:10.0), child:new Flare("assets/flares/Heart", _lives < 5)),
												]
											)
										]
									),
									new Expanded(child:new Column
									(
										crossAxisAlignment: CrossAxisAlignment.end,
										children:<Widget>
										[
											new Container(margin:const EdgeInsets.only(bottom:7.0), child:ShadowText("SCORE", spacing: 5.0, fontFamily: "Roboto", fontSize: 19.0)),
											//new Container(margin:const EdgeInsets.only(bottom:7.0), child:ShadowText(_score.toString(), fontFamily: "Inconsolata", fontSize: 50.0))
											new GameScore(_score)
										]
									)),
								]
							)
						),
						!hasMonitorCoordinates || _showHighScores ? new Container() : new Positioned(
							left: CODE_BOX_MARGIN_LEFT,
							top: CODE_BOX_MARGIN_TOP,
							width: CODE_BOX_SCREEN_WIDTH,
							height: CODE_BOX_SCREEN_HEIGHT - STDOUT_HEIGHT - STDOUT_PADDING,
							child: new CodeBoxWidget(
									_contents, 
									_lineOfInterest, 
									_highlight, 
									_highlightAlpha
								)
						),
						!hasMonitorCoordinates || _showHighScores ? new Container() : new Positioned(
							left: CODE_BOX_MARGIN_LEFT,
							top: CODE_BOX_MARGIN_TOP + CODE_BOX_SCREEN_HEIGHT - STDOUT_HEIGHT - STDOUT_PADDING,
							width: CODE_BOX_SCREEN_WIDTH,
							height: STDOUT_HEIGHT + STDOUT_PADDING,
							child: new Container
							(
								color: const Color.fromARGB(18, 255, 159, 159),
								child: new Column
								(
									crossAxisAlignment: CrossAxisAlignment.start,
									mainAxisSize: MainAxisSize.max,
									children: <Widget>
									[
										new Container
										(
											width: double.infinity,
											color: const Color.fromARGB(18, 255, 159, 159),
											padding: const EdgeInsets.only(left:15.0, top:12.0, bottom:12.0),
											child: new Text("TERMINAL", style: new TextStyle(color: new Color.fromARGB(128, 255, 255, 255), fontFamily: "Inconsolata", fontWeight: FontWeight.w700, fontSize: 16.0, decoration: TextDecoration.none))
										),
										new Expanded
										(
											child:new Container
											(
												padding: const EdgeInsets.only(left:15.0, top:12.0, bottom:12.0),
												child: StdoutDisplay(_stdoutQueue.join("\n") + "\n ")//new Text("Syncing files to iPhone 8...", style: new TextStyle(color: new Color.fromARGB(255, 255, 255, 255), fontFamily: "Inconsolata", fontWeight: FontWeight.w700, fontSize: 16.0, decoration: TextDecoration.none))
											)
										)
									],
								)
							)
						),
						!hasMonitorCoordinates || !_showHighScores ? new Container() : new Positioned
						(
							left: CODE_BOX_MARGIN_LEFT,
							top: CODE_BOX_MARGIN_TOP,
							width: CODE_BOX_SCREEN_WIDTH,
							height: CODE_BOX_SCREEN_HEIGHT,
							child:new Container
							(
								margin:const EdgeInsets.only(left:20.0, top: 15.0, right:300.0, bottom:20.0),
								child:new HighScoresScreen(_server?.highScores?.scores, _highScore)
							)
						),
						!hasMonitorCoordinates ? new Container() : new Positioned
						(
							left: CODE_BOX_MARGIN_LEFT,
							top: CODE_BOX_MARGIN_TOP,
							width: CODE_BOX_SCREEN_WIDTH,
							height: CODE_BOX_SCREEN_HEIGHT,
							child:new Column
							(
								crossAxisAlignment: CrossAxisAlignment.end,
								mainAxisAlignment: MainAxisAlignment.end,
								children: <Widget>
								[
									new Container
									(
										width: 90.0,
										height: 40.0,
										margin: const EdgeInsets.only(bottom:20.0, right:20.0),
										child:new FlatButton
										(
											color: const Color.fromRGBO(255, 255, 255, 0.5),
											disabledColor: const Color.fromRGBO(255, 255, 255, 0.2),
											disabledTextColor: const Color.fromRGBO(255, 255, 255, 0.5),
											child:new Text("restart", style: new TextStyle(color: new Color.fromARGB(255, 255, 255, 255), fontFamily: "Inconsolata", fontWeight: FontWeight.w700, fontSize: 16.0, decoration: TextDecoration.none)),
											onPressed:!_allowReinit ? null : ()
											{
												if(_server != null)
												{
													_server.restartGame();
												}
											}
										)
									),
									new Container
									(
										width: 90.0,
										height: 40.0,
										margin: const EdgeInsets.only(bottom:20.0, right:20.0),
										child:new FlatButton
										(
											color: const Color.fromRGBO(255, 255, 255, 0.5),
											disabledColor: const Color.fromRGBO(255, 255, 255, 0.2),
											disabledTextColor: const Color.fromRGBO(255, 255, 255, 0.5),
											child:new Text("run", style: new TextStyle(color: new Color.fromARGB(255, 255, 255, 255), fontFamily: "Inconsolata", fontWeight: FontWeight.w700, fontSize: 16.0, decoration: TextDecoration.none)),
											onPressed:!_allowReinit ? null : ()
											{
												if(_server != null)
												{
													_server.flutterTask = null;

													initFlutterTask();

													_flutterTask.load(targetDevice).then((success)
													{
														_allowReinit = true;
														_server.flutterTask = _flutterTask;
													});
												}
											}
										)
									)
								]
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
