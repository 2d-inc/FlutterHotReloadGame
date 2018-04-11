import 'dart:async';
import 'dart:convert';
import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flutter/rendering.dart";
import "package:web_socket_channel/web_socket_channel.dart";
import "package:web_socket_channel/io.dart";
import "dart:io";
import "decorations/dotted_grid.dart";
import "game_controls/game_slider.dart";
import "game_controls/game_radial.dart";
import "lobby.dart";
import "in_game.dart";
import "character_scene.dart";
import "dart:math";

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
	// This widget is the root of your application.
	@override
	Widget build(BuildContext context) {
		return new MaterialApp(
			title: "Terminal",
			home: new MyHomePage(
				title: "Terminal"
			)
		);
	}
}

class MyHomePage extends StatefulWidget 
{
	MyHomePage({Key key, this.title}) : super(key: key);

	final String title;

	@override
	_MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin
{	
	static const double gamePanelRatio = 0.33;
	static const double lobbyPanelRatio = 0.66;

	bool _isPlaying = false;
	double _panelRatio = 0.66;
	double _lobbyOpacity = 1.0;
	double _gameOpacity = 0.0;

	AnimationController _panelController;
	VoidCallback _fadeCallback;
	Animation<double> _slideAnimation;
	Animation<double> _fadeLobbyAnimation;
	Animation<double> _fadeGameAnimation;
	TerminalSceneState _sceneState = TerminalSceneState.All;
	int _sceneCharacterIndex = 0;
	String _sceneMessage = "Come on, we've got a deadline to make!";

	WebSocket _socket;

	bool _isReady = false;
	List<bool> _arePlayersReady;

	_connect()
	{
		String address;
		if(Platform.isAndroid)
		{
			address = "10.0.2.2";
		}
		else
		{
			address = InternetAddress.LOOPBACK_IP_V4.address;
		}
		WebSocket.connect("ws://"+ address + ":8080/ws").then(
			(WebSocket ws)
			{
				print("CONNECTED");
				_socket = ws;
				_socket.pingInterval = const Duration(seconds: 5);
				ws.listen((message)
				{
					var jsonMsg = JSON.decode(message);
					print("GOT MESSAGE $jsonMsg");

					try
					{
						var jsonMsg = JSON.decode(message);
						String msg = jsonMsg['message'];
						
						switch(msg)
						{
							case "playerList":
								List<bool> statusList = jsonMsg['payload'];
								setState(() => _arePlayersReady = statusList);
								break;
							default:
								print("UNKNOWN MESSAGE: $jsonMsg");
								break;
						}
					}
					on FormatException catch(e)
					{
						print("Wrong Message Formatting, not JSON: ${message}");
						print(e);
					}

				}, 
				onDone: _connect); // Try to reconnect when server drops
			}
		)
		.catchError(
			(e)
			{
				if(e is SocketException)
				{
					// Try to reconnect if server is unreachable
					print("RETRY $e");
					new Timer(const Duration(seconds: 5), _connect);
				}
				else
				{
					print("WEBSOCKET ERROR: $e");
				}
			}
		)
		.timeout(const Duration(seconds: 5), onTimeout: _connect);
	}

	@override
	initState()
	{
		super.initState(); 
		_arePlayersReady = [_isReady];
		_connect();

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
		print("DISPOSING");
		_socket?.close(99, "DISPOSING");
		_panelController.dispose();
		super.dispose();
	}

	void _handleReady()
	{
		setState(
			()
			{
				_isReady = !_isReady;
				String readyMsg = JSON.encode(
					{
						"message": "ready", 
						"payload": _isReady
					}	
				);
				_socket?.add(readyMsg);
			}
		);
	}

	void _handleStart()
	{
		// TODO: Server logic
		double endOpacity = _isPlaying ? 1.0 : 0.0;

		_fadeLobbyAnimation = new Tween<double>(
			begin: _lobbyOpacity,
			end: endOpacity,
		).animate(new CurvedAnimation(
				parent: _panelController,
				curve: new Interval(0.0, 0.33, curve: Curves.easeInOut)
			)
		);

		double endPanelRatio = _isPlaying ? lobbyPanelRatio : gamePanelRatio;
		_slideAnimation = new Tween<double>(
			begin: _panelRatio,
			end: endPanelRatio
		).animate(new CurvedAnimation(
				parent: _panelController,
				curve: new Interval(0.34, 0.66, curve: Curves.easeInOut)
			)
		);

		_fadeGameAnimation = new Tween<double>(
			begin: _gameOpacity,
			end: 1.0
		).animate(new CurvedAnimation(
			parent: _panelController,
			curve: new Interval(0.33, 1.0, curve: Curves.decelerate)
		));

		_isPlaying = !_isPlaying;
		_panelController.forward();

		setState(() 
		{
			_sceneState = TerminalSceneState.Upset;
			_sceneCharacterIndex = new Random().nextInt(4);//rand()%4;
			_sceneMessage = "Set padding to 20!";
		});
	}

	void _backToLobby(TapUpDetails details)
	{
		if(_isPlaying)
		{
			_panelController.reverse();
			_isPlaying = !_isPlaying;
		}
		setState(() 
		{
			_sceneState = TerminalSceneState.All;
			_sceneMessage = "Come on, we've got a deadline to make!";
		});
	}

	@override
	Widget build(BuildContext context) 
	{
		// List<bool> ready = [true, false, false, true];
		return new Container(
			decoration:new BoxDecoration(color:Colors.white),
			child:new Row(
				children: <Widget>[
					new GestureDetector(
						onTapUp: _backToLobby,
						child:	new Container(
							width: MediaQuery.of(context).size.width * _panelRatio,
							// decoration: new BoxDecoration
							// (
							// 	image: new DecorationImage
							// 	(
							// 		image: new AssetImage("assets/images/lobby_background.png"),
							// 		fit: BoxFit.fitHeight
							// 	)
							// ),
							child:new Stack
							(
								children:<Widget>
								[
									new TerminalScene(state:_sceneState, characterIndex: _sceneCharacterIndex, message:_sceneMessage)
								]	
							)
						)
						// new Container(
						// 	width: MediaQuery.of(context).size.width * _panelRatio,
						// 	decoration: new BoxDecoration(
						// 		image: new DecorationImage(
						// 			image: new AssetImage("assets/images/lobby_background.png"),
						// 			fit: BoxFit.fitHeight
						// 	),
						// 	)
						// )
					),
					new Expanded(
						child:new Container(
							padding: new EdgeInsets.all(12.0),
							decoration:new DottedGrid(),
							child: new Container(
								decoration: new BoxDecoration(border: new Border.all(color: const Color.fromARGB(127, 72, 196, 206)), borderRadius: new BorderRadius.circular(3.0)),
								padding: new EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 6.0),
								child: new Column(
									children: 
									[
										// Title Row
										new Row(children: 
											[	
												new Text("SYSTEM ONLINE", style: new TextStyle(color: new Color.fromARGB(255, 167, 230, 237), fontFamily: "Inconsolata", fontSize: 6.0, decoration: TextDecoration.none, letterSpacing: 0.4)),
												new Text(" > MILESTONE INITIATED", style: new TextStyle(color: new Color.fromARGB(255, 86, 234, 246), fontFamily: "Inconsolata", fontSize: 6.0, decoration: TextDecoration.none, letterSpacing: 0.5))
											]
										),
										// Two decoration lines underneath the title
										new Row(children: [ new Expanded(child: new Container(margin: new EdgeInsets.only(top:5.0), color: const Color.fromARGB(77, 167, 230, 237), height: 1.0)) ]),
										new Row(children: [ new Expanded(child: new Container(margin: new EdgeInsets.only(top:5.0), color: const Color.fromARGB(77, 167, 230, 237), height: 1.0)) ]), 
										_isPlaying ? new InGame(_gameOpacity, _handleReady, _handleStart) : new LobbyWidget(_isReady, _arePlayersReady, _lobbyOpacity, _handleReady, _handleStart),
										new Container(
											margin: new EdgeInsets.only(top: 10.0),
											alignment: Alignment.bottomRight,
											child: new Text("V0.1", style: const TextStyle(color: const Color.fromARGB(255, 50, 69, 71), fontFamily: "Inconsolata", fontWeight: FontWeight.bold, fontSize: 12.0, decoration: TextDecoration.none, letterSpacing: 0.9))
										),
										new Row(children: [ new Expanded(child: new Container(margin: new EdgeInsets.only(top:5.0), color: const Color.fromARGB(77, 167, 230, 237), height: 1.0)) ]),
									]
								)
							)
						)
					)
				],
			)
		);
	}
}