import 'dart:async';
import 'dart:convert';
import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flutter/rendering.dart";
import 'package:flutter/services.dart';
import "dart:io";
import "decorations/dotted_grid.dart";
import "lobby.dart";
import "in_game.dart";
import "character_scene.dart";
import "command_timer.dart";
import "dart:math";

void main() 
{
	// Hide UI top and bottom bar
	SystemChrome.setEnabledSystemUIOverlays([]);
	runApp(new MyApp());
}

class MyApp extends StatelessWidget {
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
	static const MethodChannel platform = const MethodChannel('2d.hot_reload.io/battery');

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
	String _batteryLevel = "LOADING%";
	DateTime _commandStartTime = new DateTime.now();
	DateTime _commandEndTime = new DateTime.now().add(const Duration(seconds:10));

	WebSocketClient _client;

	bool _isReady = false;
	bool _gameOver = false;
	List<bool> _arePlayersReady;

	List _gameCommands = [];

	int _lastTap = 0;
	int _tapCount = 0;

	@override
	initState()
	{
		super.initState();
		_arePlayersReady = [_isReady];
		_client = new WebSocketClient(this);
		Future batteryQuery = platform.invokeMethod('getBatteryLevel');
		// batteryQuery.then((int percent) => setState(() => _batteryLevel = "$percent%"));
		batteryQuery.then(
			(percent) 
			{
				print("JUST GOT THE BATTERY LEVEL: %$percent");
				setState(() => _batteryLevel = "$percent%");
			}).catchError((e) 
			{
				print("Just got an error!====\n$e");
			}/* , test: (e) => e is FormatException */);
		resetSceneMessage();
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

	void _backToLobby()
	{
		setState(() 
		{
			if(_isPlaying)
			{
				_panelController.reverse();
				_isPlaying = !_isPlaying;
			}
			_sceneState = TerminalSceneState.All;
			resetSceneMessage();
		});
	}

	void onGameStart(List commands)
	{
		if(!_isReady)
		{
			print("THIS PLAYER ISN'T READY YET");
			return;
		}

		setState(() => _gameCommands = commands);
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

		_panelController.forward();

		setState(() 
		{
			_isPlaying = !_isPlaying;
			_sceneState = TerminalSceneState.Upset;
			_sceneCharacterIndex = new Random().nextInt(4);//rand()%4;
			_sceneMessage = null;
			_commandStartTime = new DateTime.now();
			_commandEndTime = new DateTime.now().add(new Duration(seconds: 60));
		});
	}

	void onNewTask(Map task)
	{
		String msg = task['message'] as String;
		int time = task['expiry'] as int;

		setState(
			() {
				_sceneMessage = msg;
				_commandStartTime = new DateTime.now();
				_commandEndTime = new DateTime.now().add(new Duration(seconds: time));
			}
		);
	}

	void onTaskFail(String msg)
	{
		setState(()
		{
			_sceneMessage = msg;
		});
	}

	void onTaskComplete(String msg)
	{
		setState(()
		{
			_sceneMessage = msg;
		});
	}

	void gameOver()
	{
		List<bool> resetList = new List.filled(_arePlayersReady.length, false);
		setState(
			()
			{
				_gameCommands = [];
				_arePlayersReady = resetList;
				_isReady = false;
			}
		);
		_backToLobby(); // TODO: show the game over screen instead
	}

	// Should be called within a set state.
	resetSceneMessage()
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
			resetSceneMessage();
		});
	}

	set isReady(bool isIt)
	{
		setState(() => _isReady = isIt);
	}

	_validateIpAddress(String ip)
	{
		print("VALIDATING $ip");
		List<String> values = _ipInputController.text.split('.');
		if(values.length != 4)
		{
			print("INVALID IP");
			return false;
		}
		else
		{
			for(String s in values)
			{
				int ipValue = int.parse(s, onError: (source){});
				ipValue = ipValue ?? -1;
				if(ipValue < 0 || ipValue > 255)
				{
					print("INVALID INPUT VALUES");
					return false;
				}
			}
		}
		return true;
	}

	final TextEditingController _ipInputController = new TextEditingController();

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
											new Text(" > MILESTONE INITIATED", style: new TextStyle(color: new Color.fromARGB(255, 86, 234, 246), fontFamily: "Inconsolata", fontSize: 6.0, decoration: TextDecoration.none, letterSpacing: 0.5)),
											new Expanded(child: new Container()),
											new GestureDetector( 
												onTap: () {
													int now = new DateTime.now().millisecondsSinceEpoch;
													int diff = now - _lastTap;
													print(diff);
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
																		decoration: new InputDecoration( hintText:  "IP ADDRESS"), autofocus: true, maxLength: 15, maxLines:  1, keyboardType: TextInputType.number
																		),
																		actions: 
																		[
																			new FlatButton(
																				child : new Text("OK"),
																				onPressed: ()
																				{
																					String ip = _ipInputController.text;
																					if(_validateIpAddress(ip))
																					{
																						_client.address = ip;
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
														print("RESET COUNT");
														_tapCount = 1;
													}

													_lastTap = now;
												},
												child: Text(_batteryLevel, style: new TextStyle(color: new Color.fromARGB(255, 167, 230, 237), fontFamily: "Inconsolata", fontSize: 6.0, decoration: TextDecoration.none, letterSpacing: 0.4)))
										]
									),
									// Two decoration lines underneath the title
									new Row(children: [ new Expanded(child: new Container(margin: new EdgeInsets.only(top:5.0), color: const Color.fromARGB(77, 167, 230, 237), height: 1.0)) ]),
									new Row(children: [ new Expanded(child: new Container(margin: new EdgeInsets.only(top:5.0), color: const Color.fromARGB(77, 167, 230, 237), height: 1.0)) ]), 
									_isPlaying ? 
										new InGame(_gameOpacity, _backToLobby, _gameCommands, isOver: _gameOver)
										: new LobbyWidget(_isReady, _arePlayersReady, _lobbyOpacity, _client?.onReady, _client?.onStart),
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
	String address;

	WebSocketClient(this._terminal)
	{
		if(Platform.isAndroid)
		{
			address = "192.168.1.108";//"10.0.2.2";
		}
		else
		{
			address = InternetAddress.LOOPBACK_IP_V4.address;
		}
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
							case "commandsList":
								_terminal.onGameStart(payload as List);
								break;
							case "gameOver":
								_terminal.gameOver();
								break;
							case "newTask":
								_terminal.onNewTask(payload as Map);
								break;
							case "playerList":
								List<bool> boolList = [];
								for(var b in payload) // Workaround for Dart throw
								{
									if(b is bool) boolList.add(b);
								}
								_terminal.arePlayersReady = boolList;
								break;
							case "taskFail":
								_terminal.onTaskFail(payload as String);
								break;
							case "taskComplete":
								_terminal.onTaskComplete(payload as String);
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