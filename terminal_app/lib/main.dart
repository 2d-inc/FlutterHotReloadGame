import 'dart:async';
import 'dart:convert';
import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flutter/rendering.dart";
import "dart:io";
import "decorations/dotted_grid.dart";
import "lobby.dart";
import "in_game.dart";
import "character_scene.dart";
import "command_timer.dart";
import "dart:math";

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
	// This widget is the root of your application.
	@override
	Widget build(BuildContext context) {
		return new MaterialApp(
			title: "Terminal",
			home: new Terminal(
				title: "Terminal"
			)
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
	String _sceneMessage = "Waiting for 2 players!";
	DateTime _commandStartTime = new DateTime.now();
	DateTime _commandEndTime = new DateTime.now().add(const Duration(seconds:10));

	WebSocketClient _client;

	bool _isReady = false;
	bool _gameOver = false;
	List<bool> _arePlayersReady;

	@override
	initState()
	{
		super.initState(); 
		_arePlayersReady = [_isReady];
		_client = new WebSocketClient(this);
		updateSceneMessage();
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
		_client.dispose();
		_panelController.dispose();
		super.dispose();
	}

	bool handleReady()
	{
		bool readyState = !_isReady;
		setState(() => _isReady = readyState);
		return readyState;
	}

	void _handleStart()
	{
		// TODO: Server logic
		_client.onStart();
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
			

			// Fake setting command time and command
			_sceneMessage = "Set padding to 20!";
			_commandStartTime = new DateTime.now();
			_commandEndTime = new DateTime.now().add(const Duration(seconds:10));
		});
		/* TODO: [debug] remove 
		_gameOver = false;
		new Timer(const Duration(seconds: 2), () {
			setState( () {
				_gameOver = true;
			} );
		});
		*/
	}

	void _backToLobby()
	{
		if(_isPlaying)
		{
			_panelController.reverse();
			_isPlaying = !_isPlaying;
			gameOver(); /* TODO: [debug] remove */
		}
		setState(() 
		{
			_sceneState = TerminalSceneState.All;
			updateSceneMessage();
		});
	}

	void onGameStart(List commands)
	{
		print("I GOT THESE COMMANDS: $commands");
	}

	void gameOver()
	{
		List<bool> resetList = new List.filled(_arePlayersReady.length, false);
		// Use setters
		arePlayersReady = resetList;
		isReady = false;
	}

	// Should be called within a set state.
	updateSceneMessage()
	{
		String message = _arePlayersReady.fold<int>(0, (int count, bool value) { if(value) { count++; } return count;} ) >= 2 ? "Come on, we've got a deadline to make!" : "Waiting for 2 players!";
		if(message != _sceneMessage)
		{
			_sceneMessage = message;
		}
	}

	set arePlayersReady(List<bool> readyList)
	{
		setState(()
		{
			_arePlayersReady = readyList;
			updateSceneMessage();
		});
	}

	set isReady(bool isIt)
	{
		setState(() => _isReady = isIt);
	}

	@override
	Widget build(BuildContext context) 
	{
		
		return new Stack
		(
			fit:StackFit.loose,
			//alignment: Alignment.,
			children:<Widget>
			[
				new Positioned
				(
					width:MediaQuery.of(context).size.width * (1.0-_panelRatio),
					top:0.0,
					bottom:0.0,
					right:0.0, 
					child:new Container
					(
						padding: new EdgeInsets.all(12.0),
						decoration:new DottedGrid(),
						child:new Container
						(
							decoration: new BoxDecoration(border: new Border.all(color: const Color.fromARGB(127, 72, 196, 206)), borderRadius: new BorderRadius.circular(3.0)),
							padding: new EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 6.0),
							child: new Column
							(
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
									_isPlaying ? new InGame(_gameOpacity, _handleStart, _backToLobby, isOver: _gameOver) : new LobbyWidget(_isReady, _arePlayersReady, _lobbyOpacity, _client.onReady, _handleStart),
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
				),
				new Positioned
				(
					left:0.0,
					top:0.0,
					bottom:0.0,
					width:MediaQuery.of(context).size.width * _panelRatio,
					child: new GestureDetector( onTap: _backToLobby, child: 
						new Container(
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
									new TerminalScene(state:_sceneState, characterIndex: _sceneCharacterIndex, message:_sceneMessage, startTime:_commandStartTime, endTime:_commandEndTime),
									new Container(
										margin: new EdgeInsets.only(left:20.0, right:20.0, top:20.0),
										height: 50.0,
										child:new CommandTimer(opacity:_gameOpacity, startTime:_commandStartTime, endTime:_commandEndTime)
									)
								]	
							)
						)
					),
				)			
			],
		);
	}
}

class WebSocketClient
{
	WebSocket _socket;
	_TerminalState _terminal;

	WebSocketClient(this._terminal)
	{
		connect();
	}

    static String formatJSONMessage<T>(String msg, T payload)
    {
        return json.encode({
            "message": msg,
            "payload": payload
        });
    }

	dispose()
	{
		_socket?.close(99, "DISPOSING");
	}

	void onReady()
	{
		bool state = _terminal.handleReady();
		_socket?.add(formatJSONMessage("ready", state));
	}

	onStart()
	{
		_socket?.add(formatJSONMessage("startGame", true));
	}

	connect()
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
					try
					{
						var jsonMsg = json.decode(message);
						String msg = jsonMsg['message'];
						print("GOT MESSAGE $jsonMsg");
						var payload = jsonMsg['payload'];
						
						switch(msg)
						{
							case "playerList":
								List<bool> boolList = [];
								for(var b in payload) // Workaround for Dart throw
								{
									if(b is bool) boolList.add(b);
								}
								_terminal.arePlayersReady = boolList;
								break;
							case "gameOver":
								// Reset state
								_terminal.gameOver();
								break;
							case "commandsList":
								_terminal.onGameStart(payload as List);
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
				onDone: connect); // Try to reconnect when server drops
			}
		)
		.catchError(
			(e)
			{
				if(e is SocketException)
				{
					// Try to reconnect if server is unreachable
					print("RETRY $e");
					new Timer(const Duration(seconds: 5), connect);
				}
				else
				{
					print("WEBSOCKET ERROR: $e");
				}
			}
		)
		.timeout(const Duration(seconds: 5), onTimeout: connect);
	}
}