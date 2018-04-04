import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flutter/rendering.dart";
import "package:web_socket_channel/web_socket_channel.dart";
import "package:web_socket_channel/io.dart";
import "dart:io";
import "command_panel.dart";
import "players_widget.dart";
import "decorations/dotted_grid.dart";
import "game_controls/game_slider.dart";
import "game_controls/game_radial.dart";
import "lobby.dart";
import "in_game.dart";

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
	MyHomePage({Key key, this.title}) : super(key: key)
	{
		WebSocket.connect("ws://192.168.1.156:8080/ws").then((ws)
		{
			print("CONNECTED");
			socket = ws;
			ws.listen((message)
			{
				print("GOT MESSAGE $message");
			});
		});
		
	}
	final String title;
	WebSocket socket;

	@override
	_MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin
{	
	static const double gamePanelRatio = 0.33;
	static const double lobbyPanelRatio = 0.66;

	List<Widget> _buttonList;

	bool _isPlaying = false;
	double _panelRatio = 0.66;
	double _lobbyOpacity = 1.0;

	AnimationController _panelController;
	AnimationStatusListener _slideListener;
	AnimationStatusListener _fadeListener;
	VoidCallback _fadeCallback;
	VoidCallback _slideCallback;
	Animation<double> _slideAnimation;
	Animation<double> _fadeAnimation;

	@override
	initState()
	{
		super.initState();

		_panelController = new AnimationController(vsync: this);
		
		_fadeCallback = () 
		{
			setState(
				()
				{
					_lobbyOpacity = _fadeAnimation.value;
				}
			);
		};
		_slideCallback = ()
		{
			setState(
				()
				{
					_panelRatio = _slideAnimation.value;
				}
			);
		};

		_fadeListener = (AnimationStatus s){
			if(s == AnimationStatus.completed)
			{
				_panelController.removeListener(_fadeCallback);
				_panelController.removeStatusListener(_fadeListener);
				double end = _isPlaying ? lobbyPanelRatio : gamePanelRatio;
				_slideAnimation = new Tween<double>(
					begin: _panelRatio,
					end: end
				).animate(_panelController);
				_panelController
					..value = 0.0
					..animateTo(1.0, curve: Curves.easeInOut, duration: const Duration(milliseconds: 250))
					..addStatusListener(_slideListener)
					..addListener(_slideCallback);
			}
		};

		_slideListener = (AnimationStatus s)
		{
			if(s == AnimationStatus.completed)
			{
				_panelController.removeListener(_slideCallback);
				_panelController.removeStatusListener(_slideListener);
				_panelController
					..stop()
					..addListener(_fadeCallback)
					..addStatusListener(_fadeListener);
				_isPlaying = !_isPlaying;		
			}
		};

		_panelController
			..addListener(_fadeCallback)
			..addStatusListener(_fadeListener);

	}

	void _handleTap()
	{
		widget.socket.add("hi");
	}

	void _handleReady()
	{
		// TODO:
	}

	void _handleStart()
	{
		// TODO: Server logic
		double begin = _isPlaying ? 0.0 : 1.0;
		double end = _isPlaying ? 1.0 : 0.0;

		_fadeAnimation = new Tween<double>(
			begin: begin,
			end: end
		).animate(_panelController);
		_panelController
			..value = 0.0
			..animateTo(1.0, curve: Curves.easeInOut, duration: const Duration(milliseconds: 250));
	}

	expand()
	{

	}

	@override
	Widget build(BuildContext context) 
	{
		return new Container(
			decoration:new BoxDecoration(color:Colors.white),
			child:new Row(
				children: <Widget>[
					new Container(
						width: MediaQuery.of(context).size.width * _panelRatio,
						decoration: new BoxDecoration(
							image: new DecorationImage(
								image: new AssetImage("assets/images/lobby_background.png"),
								fit: BoxFit.fitHeight
						),
						)
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
										_panelRatio == gamePanelRatio ? new InGame(1.0-_lobbyOpacity, _handleReady, _handleStart) : new LobbyWidget(_lobbyOpacity, _handleReady, _handleStart),
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

	addButton(Widget w)
	{
		_buttonList.add(w);
	}

	get children => _buttonList;
}