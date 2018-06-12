import 'dart:async';
import 'dart:collection';
import 'dart:math';

import "package:flutter/animation.dart";
import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import "flare_widget.dart";
import 'flutter_task.dart';
import "game_over_screen.dart";
import "high_scores.dart";
import "high_scores_screen.dart";
import "monitor_scene.dart";
import "progress_bar.dart";
import "score.dart";
import "score_dopamine.dart";
import "server.dart";
import "shadow_text.dart";
import 'sound.dart';
import "stdout_display.dart";
import "tasks/command_tasks.dart";
import "text_render_object.dart";

/// The main component of the application. 
/// The [MonitorState] keeps track of the state of the whole application.
class Monitor extends StatefulWidget
{
	final String title;
	
	Monitor({Key key, this.title}) : super(key:key);

	@override
	MonitorState createState() => new MonitorState();
}

/// State for the app. 
/// It shows the main window, with a background image with a flickering neon on top.
/// There'll be a monitor occupying most of the window, with a character on its left.
/// If no game is in progress, the monitor will show the highscores from the previous games. The character on the left
/// will be playing its "happy" idle animation, while waiting for 2 or more players to start a game.
/// If a game is being played, its status will be shown: 
/// - on the top-left the app shows the team's lives, together with a progress bar;
/// - on the top-right corner there's the current score;
/// - the monitor will show the actual code that's being reloaded on-the-fly, as commands are received from the clients;
/// - "Dopamine" are also displayed when certain events occur (e.g. life is lost, the score is increased);
/// - a 'stdout' panel is shown underneath the code, to visualize the communication between this Flutter app, and its
/// "Hot Reload" counterpart in the backened.
/// 
/// When a game ends, the monitor will show all the relevant stats for this game.
/// 
/// There are also two buttons present in the bottom-right corner of the monitor:
/// - the "restart" button will stop a game if it's in progress, and allow players to restart;
/// - the "run" button runs (or restarts if already running) the app in the Simulator.
/// In fact the two buttons are supposed to be hidden behind a Simulator that should be overlayed on top of the window
/// and placed "on top" of the phone dock image.
class MonitorState extends State<Monitor> with TickerProviderStateMixin
{
	static const int HIGHLIGHT_ALPHA_FULL = 56;
	static const int MAX_FLICKER_COUNT = 6;
    static const double STDOUT_PADDING = 41.0;
    static const double STDOUT_HEIGHT = 150.0 - STDOUT_PADDING;
    static const int STDOUT_MAX_LINES = 5;
    static const String targetDevice = '"iPhone 8"';
    static const String logoAppLocation = "~/Projects/BiggerLogo/logo_app";
	static const int statsDropSeconds = 15;

    /// Which line should be highligted.
	double _lineOfInterest = 0.0;
    /// An object representing a line highlight for the Monitor.
	Highlight _highlight;
	List<Sound> _sounds;
    /// The object that pipes messages to the Objective-C backend.
	FlutterTask _flutterTask;
    /// This Widget is the entry point for the whole app, thus it owns the [GameServer].
	GameServer _server;
	bool _ready = false;
    /// This string will be loaded with a template file so that it can replace certain values
    /// as the inputs from the Clients are received. This template will be then loaded saved 
    /// by the Simulator app, and reloaded by an ad-hoc [FlutterTask].
	String _contents;
	ListQueue<String> _stdoutQueue;
	IssuedTask _currentDisplayTask;

    /// Animation Controllers for scrolling in the code window, and for staggering the highlight effect.
	AnimationController _scrollController;
	AnimationController _highlightController;
	int _flickerCounter = 0;
	int _highlightAlpha = HIGHLIGHT_ALPHA_FULL;
	Animation<double> _scrollAnimation;
	Animation<double> _highlightAnimation;
	AnimationStatusListener _scrollStatusListener;

    /// Some Parameters for correct placement of widgets and effects.
	Offset _monitorTopLeft;
	Offset _monitorBottomRight;
	Offset _dopamineTopLeft;
	Offset _dopamineBottomRight;
    /// Start and end time for current task.
	DateTime _startTaskTime;
	DateTime _failTaskTime;
	DateTime _waitMessageTime;
    /// Which NPC should be displayed on the left.
	int _characterIndex = 0;
	int _lives = 0;
	int _score = 0;
	String _characterMessage;
	bool _showHighScores = true;
	bool _showStats = false;
	HighScore _highScore;
	DateTime _reloadTime;

	Animation<double> _progressAnimation;
	AnimationController _progressController;
	double _gameProgress = 0.0;
	DateTime _statsDropTime = new DateTime.fromMicrosecondsSinceEpoch(0);
	Timer _highScoreTimer;

    MonitorState() : _highlight = new Highlight(-1, 0, 0)
	{
		initFlutterTask();

		_stdoutQueue = new ListQueue<String>(STDOUT_MAX_LINES);
		/// Read the template file contents.
		_flutterTask.read("/lib/main_template.dart").then((contents)
		{
			_contents = contents;

			_flutterTask.write("/lib/main.dart", _contents).then((ok)
			{
				/// Start emulator.
				_flutterTask.load(targetDevice).then((success)
				{
                    /// Once the emulator has been loaded, the server can be instantiated.
					_server = new GameServer(_flutterTask, _contents);
					
                    /// Start registering the relevant callbacks on the server.
					_server.onProgressChanged = (double progress)
					{
						print("PROGRESS $progress");
					};

					_server.onLivesUpdated = ()
					{
						setState(()
						{
							_lives = max(0, _server.lives);
						});
					};

					_server.onProgressChanged = (double progress)
					{
						 setState(()
						 {
							_progressAnimation = new Tween<double>(
								begin: _gameProgress,
								end: progress
							).animate(_progressController);

							_progressController ..value = 0.0..animateTo(1.0, curve: Curves.easeInOut);
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
						if(_highScoreTimer != null)
						{
							_highScoreTimer.cancel();
						}
						setState(()
						{
							_showHighScores = false;
							_characterMessage = "GET READY FOR MY INSTRUCTIONS!";
						});
					};

					_server.onGameOver = ()
					{
						setState(()
						{
							showStats();
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

    /// Upon creation, this object is initialized by showing the lobby, and allocating all the [AnimationController] fields.
	@override
	initState()
	{
		super.initState();

		showLobby();

        /// Scroll the [CodeBoxWidget] to the right line.
		_scrollController = new AnimationController(duration: const Duration(milliseconds: 350), vsync: this)
			..addListener(
				() {
					setState(() 
					{
						_lineOfInterest = _scrollAnimation.value;
					});
				}		
		);

        /// Highlight by flickering 3 times the relevant line.
		_highlightController = new AnimationController(vsync: this, duration: new Duration(milliseconds: 100))
			..addListener(
				()
				{
					setState(
						()
						{
							this._highlightAlpha = _highlightAnimation.value.toInt();
							/// Stop the animation ELSE flicker
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

        /// Interpolate the game progress bar to a new value
		_progressController = new AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
			..addListener(
				()
				{
					setState(
						()
						{
							this._gameProgress = _progressAnimation.value;
						}
					);
				}
			);

        /// Wait for the scroll animation to complete, and start the highlighting animation right after.
		_scrollStatusListener = (AnimationStatus state) {
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

    /// When a game is over, stats replace the Code window.
	void showStats()
	{
		_characterIndex = 0;
		_characterMessage = "IT'S OVER!";
		_startTaskTime = null;
		_failTaskTime = null;
		_showHighScores = true;
		_showStats = true;

		_statsDropTime = new DateTime.now().add(const Duration(seconds:1));
		if(_highScoreTimer != null)
		{
			_highScoreTimer.cancel();
		}
		_highScoreTimer = new Timer(const Duration(seconds:statsDropSeconds), ()
		{
			setState(()
			{
                /// Show the lobby after a few seconds with the stats.
				showLobby();
			});
		});
	}

    /// Sets the appropriate flags and fields to show the lobby.
	void showLobby()
	{
		_characterIndex = 0;
		_characterMessage = "WAITING FOR 2-4 PLAYERS!";
		_startTaskTime = null;
		_failTaskTime = null;
		_showHighScores = true;
		_showStats = false;
	}

    /// This function (re)initializes the [FlutterTask] field, and its callbacks.
	initFlutterTask()
	{
		_ready = false;
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

	@override
	Widget build(BuildContext context)
	{
		Size sz = MediaQuery.of(context).size;

		final bool hasMonitorCoordinates = _monitorTopLeft != null && _monitorBottomRight != null;

		final double CODE_BOX_SCREEN_WIDTH = hasMonitorCoordinates ? _monitorBottomRight.dx - _monitorTopLeft.dx : 0.0;
		final double CODE_BOX_SCREEN_HEIGHT = hasMonitorCoordinates ? _monitorBottomRight.dy - _monitorTopLeft.dy : 0.0;
		final double CODE_BOX_MARGIN_LEFT = hasMonitorCoordinates ? _monitorTopLeft.dx : 0.0;
		final double CODE_BOX_MARGIN_TOP = hasMonitorCoordinates ? _monitorTopLeft.dy : 0.0;

		final double secondsSinceDrop = max(0.0, (new DateTime.now().millisecondsSinceEpoch - _statsDropTime.millisecondsSinceEpoch)/1000.0);
        /// This [Stack] is the main component of the app.
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
                                            /// The left part of the screen is occupied by the NPC.
											new MonitorScene(state:MonitorSceneState.BossOnly, reloadDateTime:_reloadTime, characterIndex: _characterIndex, message:_characterMessage, startTime: _startTaskTime, endTime:_failTaskTime, monitorExtentsCallback:(Offset topLeft, Offset bottomRight, Offset dopamineTopLeft, Offset dopamineBottomRight)
											{
												if(_monitorTopLeft != topLeft || _monitorBottomRight != bottomRight || _dopamineTopLeft != dopamineTopLeft || _dopamineBottomRight != dopamineBottomRight)
												{
													setState(() 
													{
														_monitorTopLeft = topLeft;
														_monitorBottomRight = bottomRight;
														_dopamineTopLeft = dopamineTopLeft;
														_dopamineBottomRight = dopamineBottomRight;
													});
												}	

											})
										]
									)
						),
                        /// A Top Row with the Lives, Progress bar on the left, and Score on the right.
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
											),
											new Container(margin: const EdgeInsets.only(top: 17.0), child: new ShadowText("PROGRESS:", spacing: 5.0, fontFamily: "Roboto", fontSize: 19.0)),
											new Container
											(
												margin: const EdgeInsets.only(top: 5.0), 
												child: new ProgressBar(_gameProgress),
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
								child: _showStats ? new GameOverScreen(_statsDropTime, _gameProgress, _score, _lives, _highScore == null ? 0 : _highScore.idx + 1 , _score+(_lives * GameServer.LifeMultiplier), GameServer.LifeMultiplier) : new HighScoresScreen(_server?.highScores?.topTen, _highScore)
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
											onPressed:()
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
											onPressed:()
											{
												if(_server != null)
												{
													_server.flutterTask = null;

													initFlutterTask();

													_flutterTask.load(targetDevice).then((success)
													{
														_server.flutterTask = _flutterTask;
													});
												}
											}
										)
									)
								]
							)
						),
						_server != null && hasMonitorCoordinates ? new ScoreDopamine(_server, _dopamineTopLeft, _dopamineBottomRight) : Container()
					],
			);

		return new Scaffold(
			body: new Center(child: stack)
		);
	}
}