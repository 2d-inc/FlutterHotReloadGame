import 'dart:async';
import "dart:math";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import 'package:flutter/services.dart';

import "decorations/dotted_grid.dart";
import "game/blocs/connection_bloc.dart";
import "game/blocs/game_stats_bloc.dart";
import "game/blocs/scene_bloc.dart";
import "game/game.dart";
import "game/game_provider.dart";
import "game/widgets/character_scene/terminal_scene.dart";
import "game/widgets/command_timer.dart";
import "game/widgets/flare_heart_widget.dart";
import "game/widgets/in_game.dart";
import "game/widgets/lobby_widget.dart";
import "game/widgets/terminal_dopamine.dart";
import "game/socket_client.dart";

void main() 
{
	runApp(new TerminalApp());
}

class TerminalApp extends StatelessWidget {
    
    TerminalApp()
    {
        /// Lock the App in landscape.
        SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeRight,
            DeviceOrientation.landscapeLeft,
        ]);
    }

	@override
	Widget build(BuildContext context) {
        /// The [GameProvider] wrapper exposes the [Game] object
        /// to the rest of our app, so that the necessary Widgets 
        /// will be able to access [SocketClient], [ValueNotifier]s,
        /// [Sink]s and [Stream]s as needed
		return GameProvider(
                child: MaterialApp(
                title: "Terminal",
                home: new Terminal(
                    title: "Terminal",
                )
            ),
        );
	}
}

class Terminal extends StatefulWidget 
{
	Terminal({Key key, this.title}) : super(key: key);

	final String title;

	@override
	_TerminalState createState() => new _TerminalState();
}

class _TerminalState extends State<Terminal> with SingleTickerProviderStateMixin
{
	static const double gamePanelRatio = 0.33;
	static const double lobbyPanelRatio = 0.66;
	static const MethodChannel platform = const MethodChannel('2d.hot_reload.io/android');
	static const int statsDropSeconds = 15;
	final TextEditingController _ipInputController = new TextEditingController();

    bool _isPlaying = false;
	double _panelRatio = 0.66;
	double _lobbyOpacity = 1.0;
	double _gameOpacity = 0.0;
    
	AnimationController _panelController;
	Animation<double> _slideAnimation;
	Animation<double> _fadeLobbyAnimation;
	Animation<double> _fadeGameAnimation;
	VoidCallback _fadeCallback;
	String _batteryLevel = "LOADING%";
	
    Offset _lastGlobalTouchPosition;
	int _lastTap = 0;
	int _tapCount = 0;

	int _randomSeed = 1;

	@override
	initState()
	{
		super.initState();
		Future batteryQuery = platform.invokeMethod('getBatteryLevel');
		batteryQuery.then((percent) => setState(() => _batteryLevel = "$percent%")).
			catchError(
				(e) => debugPrint("Just got an error!====\n$e"), 
				test: (e) => e is FormatException
			);
		_panelController = new AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
		_fadeCallback = () 
		{
			setState(
				()
				{
					_lobbyOpacity = _fadeLobbyAnimation?.value ?? _lobbyOpacity;
					_panelRatio = _slideAnimation?.value ?? _panelRatio;
					_gameOpacity = _fadeGameAnimation?.value ?? _gameOpacity;
				}
			);
		};
		_panelController
			..addListener(_fadeCallback);
	}

	@override
	void dispose()
	{
		_panelController.dispose();
		super.dispose();
	}

	void onGameStart()
	{
		_randomSeed = new Random().nextInt(19890926);

        /// There are three animations that start playing when a Game begins:
        /// 1. Fade out the lobby widgets by altering their opacity;
		_fadeLobbyAnimation = new Tween<double>(
			begin: _lobbyOpacity,
			end: 0.0,
		).animate(new CurvedAnimation(
				parent: _panelController,
				curve: new Interval(0.0, gamePanelRatio, curve: Curves.easeInOut)
			)
		);

        /// 2. Slide out the panel by making it occupy 2/3 of the screen;
		_slideAnimation = new Tween<double>(
			begin: _panelRatio,
			end: gamePanelRatio
		).animate(new CurvedAnimation(
				parent: _panelController,
				curve: new Interval(0.34, lobbyPanelRatio, curve: Curves.easeInOut)
			)
		);

        /// 3. Increase the opacity of all the game widgets so they become gradually visible.
		_fadeGameAnimation = new Tween<double>(
			begin: _gameOpacity,
			end: 1.0
		).animate(new CurvedAnimation(
			parent: _panelController,
			curve: new Interval(0.33, 1.0, curve: Curves.decelerate)
		));

		_panelController.forward();
	}	

    _backToLobby(Game game)
    {
        /// Alert the [Game] that the Terminal is showing again the [LobbyWidget].
        game.backToLobby();
        /// Use the same controller as in [onGameStart()] so that all the animations play in reverse,
        /// and the [LobbyWidget] is shown instead of [InGame].
        _panelController.reverse();
    }

    set isPlaying(bool isIt)
    {
        if(isIt != _isPlaying)
        {
            if(isIt)
            {
                /// Start the Animation
                onGameStart();
            }
            _isPlaying = isIt;
        }
    }

    Widget inGameHeartsBuilder(BuildContext ctx, AsyncSnapshot<GameStatistics> snapshot)
    {
        GameStatistics gs = snapshot.data;
        if(gs == null)
        {
            return Container();
        }
        int ls = gs.lives;
        return new Row
        (
            children: 
            [
                new Container(margin:const EdgeInsets.only(right:10.0), child:new FlareHeart("assets/flares/Heart", ls < 1, opacity: _gameOpacity)),
                new Container(margin:const EdgeInsets.only(right:10.0), child:new FlareHeart("assets/flares/Heart", ls < 2, opacity: _gameOpacity)),
                new Container(margin:const EdgeInsets.only(right:10.0), child:new FlareHeart("assets/flares/Heart", ls < 3, opacity: _gameOpacity)),
                new Container(margin:const EdgeInsets.only(right:10.0), child:new FlareHeart("assets/flares/Heart", ls < 4, opacity: _gameOpacity)),
                new Container(margin:const EdgeInsets.only(right:10.0), child:new FlareHeart("assets/flares/Heart", ls < 5, opacity: _gameOpacity)),
            ],
        );
    }
    
    Widget characterSceneBuilder(BuildContext ctx, AsyncSnapshot<SceneInfo> snapshot)
    {
        SceneInfo si = snapshot.data;
        if (si == null)
        {
            return Container();
        }

        Game game = GameProvider.of(ctx);

        return new Stack
            (
                children:<Widget>
                [
                    new TerminalScene(state:si.sceneState, characterIndex: si.sceneCharacterIndex, message:si.sceneMessage, startTime:si.commandStartTime, endTime:si.commandEndTime),
                    new Container(
                        margin: new EdgeInsets.only(left:20.0, right:20.0, top:20.0),
                        child: new StreamBuilder(
                            stream: game.gameStatsBloc.stream,
                            builder: inGameHeartsBuilder
                        )
                    ),
                    new Container
                    (
                        margin: new EdgeInsets.only(left:20.0, right:20.0, top:48.0),
                        height: 15.0,
                        child:new CommandTimer(opacity:_gameOpacity, startTime: si.commandStartTime, endTime: si.commandEndTime)
                    )
                ]	
            );
    }

    Widget gameColumnBuilder(BuildContext ctx, AsyncSnapshot<ConnectionInfo> snapshot)
    {
        ConnectionInfo ci = snapshot.data;
        if(ci == null)
        {
            return Container();
        }
        this.isPlaying = ci.isPlaying;
        Game game = GameProvider.of(ctx);
        String msg = snapshot.data.isConnected ? "SYSTEM ONLINE" : "SYSTEM OFFLINE";
        return new Column
                (children: 
                    [
                        /// Title Row
                        new Row(children: 
                            [
                                new Text(msg, style: new TextStyle(color: new Color.fromARGB(255, 167, 230, 237), fontFamily: "Inconsolata", fontSize: 6.0, decoration: TextDecoration.none, letterSpacing: 0.4)),
                                new Text(" > MILESTONE INITIATED", style: new TextStyle(color: new Color.fromARGB(255, 86, 234, 246), fontFamily: "Inconsolata", fontSize: 6.0, decoration: TextDecoration.none, letterSpacing: 0.5)),
                                new Expanded(child: new Container()),
                                new Text(_batteryLevel, style: new TextStyle(color: new Color.fromARGB(255, 167, 230, 237), fontFamily: "Inconsolata", fontSize: 6.0, decoration: TextDecoration.none, letterSpacing: 0.4))
                            ]
                        ),
                        /// Two decoration lines underneath the title
                        new Row(children: [ new Expanded(child: new Container(margin: new EdgeInsets.only(top:5.0), color: const Color.fromARGB(77, 167, 230, 237), height: 1.0)) ]),
                        new Row(children: [ new Expanded(child: new Container(margin: new EdgeInsets.only(top:5.0), color: const Color.fromARGB(77, 167, 230, 237), height: 1.0)) ]), 
                        ci.isPlaying ? 
                            new InGame(_gameOpacity, () => _backToLobby(game), _randomSeed) :
                            new LobbyWidget( _lobbyOpacity),
                        new Container(
                            margin: new EdgeInsets.only(top: 10.0),
                            alignment: Alignment.bottomRight,
                            child: new Text("V0.2", style: const TextStyle(color: const Color.fromARGB(255, 50, 69, 71), fontFamily: "Inconsolata", fontWeight: FontWeight.bold, fontSize: 12.0, decoration: TextDecoration.none, letterSpacing: 0.9))
                        ),
                        new Row(children: [ new Expanded(child: new Container(margin: new EdgeInsets.only(top:5.0), color: const Color.fromARGB(77, 167, 230, 237), height: 1.0)) ]),
                    ]
                );
    }

	@override
	Widget build(BuildContext context) 
	{
        final Game game = GameProvider.of(context);
		/// Hide Sofkteys&Status bar
		SystemChrome.setEnabledSystemUIOverlays([]);
		return new Listener(
            /// The Terminal app has a hidden menu accessible via a triple-tap
            /// on the top left corner of the screen. This menu allows users to specify
            /// an IP address to connect to the server locally.
			onPointerDown: (PointerDownEvent ev)
				{
					setState(() 
					{
						_lastGlobalTouchPosition = ev.position;	  
					});
					bool topLeftCorner = ev.position.dx < 75.0 && ev.position.dy < 75.0;
					if(topLeftCorner)
					{
						int now = new DateTime.now().millisecondsSinceEpoch;
						int diff = now - _lastTap;
						if(diff < 1000)
						{
							_tapCount++;
							if(_tapCount > 2)
							{
								_tapCount = 0;
								showDialog(
									context: context,
									builder: (_) => new AlertDialog(
										title: new Text("LOCAL_IP"),
										content: new TextFormField(
											controller: _ipInputController, 
											decoration: new InputDecoration( hintText: 	 "IP ADDRESS"), autofocus: true, maxLength: 15, maxLines:  1, keyboardType: TextInputType.phone
											),
											actions: 
											[
												new FlatButton(
													child : new Text("OK"),
													onPressed: ()
													{
														String ip = _ipInputController.text;
														if(validateIpAddress(ip))
														{
															if(game.client != null)
															{
																game.client.address = ip;
															}
															Navigator.of(context).pop();
														}
													}
												)
										],
									)
								);
							}
						}
						else
						{
							_tapCount = 1;
						}

						_lastTap = now;
					}
				},
			child: new Stack
			(
				fit:StackFit.loose,
				children:<Widget>
				[
					new Positioned
					(
						width:MediaQuery.of(context).size.width * (1.0-_panelRatio),
						top:0.0,
						bottom:0.0,
						right:0.0, 
						child: new Container
						(
							padding: new EdgeInsets.all(12.0),
							decoration: new DottedGrid(),
							child: new Container
							(
								decoration: new BoxDecoration(border: new Border.all(color: const Color.fromARGB(127, 72, 196, 206)), borderRadius: new BorderRadius.circular(3.0)),
								padding: new EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 6.0),
								child: new StreamBuilder(
                                        stream: game.gameConnectionBloc.stream,
                                        builder: gameColumnBuilder                                
                                )
                            )
                        )
                    ),
                    new Positioned
                    (
                        left: 0.0,
                        top: 0.0,
                        bottom: 0.0,
                        width: MediaQuery.of(context).size.width * _panelRatio,
                        child: new Container
                        (
                            child: new StreamBuilder(
                                stream: game.sceneBloc.stream,
                                builder: characterSceneBuilder
                            )
                        )
                    ),
					new Positioned
					(
						left: 0.0,
						top: 0.0,
						bottom: 0.0,
						right: 0.0,
                        /// The [TerminalDopamine] Widget wraps a [TerminalDopamineRenderObject] in order to 
                        /// display flashing messages in the [Terminal] Widget in the Main Screen. 
                        /// It necessitates of a [DopaminDelegate].
						child: new TerminalDopamine(game, touchPosition:_lastGlobalTouchPosition),
					)
				],
			)
		);
	}
}