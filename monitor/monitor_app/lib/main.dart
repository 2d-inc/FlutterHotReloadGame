import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'sound.dart';
import 'flutter_task.dart';
import 'dart:async';
import 'dart:math';
import "dart:io";
import 'sound.dart';
import 'flutter_task.dart';
import "text_render_object.dart";

Future<String> loadFileAssets(String filename) async
{
	return await rootBundle.loadString("assets/files/$filename");
}

class CodeBoxWidget extends LeafRenderObjectWidget
{
	TextRenderObject child;
	final Offset _offset;

	CodeBoxWidget(this._offset, {Key key}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		child = new TextRenderObject(screenOffset: this._offset,fontSize: 16.0);
		loadFileAssets("main.dart").then(
			(String code)
			{
				print("Got ${code.split('\n').length} lines of code!");
				child.text = code;
			}
		);
		
		return child;
	}
}

class CodeBox extends StatefulWidget
{
	final String title;
	
	CodeBox({Key key, this.title}) : super(key:key);

	@override
	CodeBoxState createState() => new CodeBoxState();
}

class CodeBoxState extends State<CodeBox>
{
	final Icon upArrowIcon;
	final Icon downArrowIcon;
	Offset _offset;
	Icon arrowIcon;
	bool upFacing = true;
	List<Sound> _sounds;
	FlutterTask _flutterTask = new FlutterTask("~/Projects/BiggerLogo/logo_app");
	Random _rng = new Random();
	bool _ready = false;
	String _contents;
	bool _isReloading;

	handleWebSocketMessage(msg) 
	{
		if(_isReloading || !_ready)
		{
			return;
		}
		_isReloading = true;
		if(_contents.indexOf("FeaturedRestaurantSimple") != -1)
		{
			_contents = _contents.replaceAll("FeaturedRestaurantSimple", "FeaturedRestaurantAligned");
		}
		else if(_contents.indexOf("CategorySimple") != -1)
		{
			_contents = _contents.replaceAll("CategorySimple", "CategoryAligned");
		}
		else if(_contents.indexOf("RestaurantsHeaderSimple") != -1)
		{
			_contents = _contents.replaceAll("RestaurantsHeaderSimple", "RestaurantsHeaderAligned");
		}
		else if(_contents.indexOf("RestaurantSimple") != -1)
		{
			_contents = _contents.replaceAll("RestaurantSimple", "RestaurantAligned");
		}
		_flutterTask.write("/lib/main.dart", _contents).then((ok)
		{
			// Start emulator.
			_flutterTask.hotReload().then((ok)
			{
				_isReloading = false;
			});
		});
	}

	CodeBoxState() :
		_offset = Offset.zero,
		upArrowIcon = new Icon(Icons.arrow_upward), 
		downArrowIcon = new Icon(Icons.arrow_downward), 
		arrowIcon = new Icon(Icons.arrow_upward)
	{
		HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 8080).then(
			(server) async
			{
				print("Serving at ${server.address}:${server.port}");
				await for (var request in server) 
				{
					 if (request.uri.path == '/ws') 
					 {
						// Upgrade a HttpRequest to a WebSocket connection.
						var socket = await WebSocketTransformer.upgrade(request);
						socket.listen(handleWebSocketMessage);
					}
					else
					{
						request.response
						..headers.contentType = new ContentType("text", "plain", charset: "utf-8")
						..write('Hello, world')
						..close();
					}
				}
			});

		_flutterTask.onReady(()
		{
			setState(() 
			{
				_ready = true;
				// TODO: Show _contents in monitor.
				
			});
		});

		// Read contents.
		_flutterTask.read("/lib/main.dart").then((contents)
		{
			// Reset all widgets.
			// _contents = contents.replaceAllMapped(new RegExp(r"(FeaturedRestaurantAligned)\('"), (Match m)
			// {
			// 	return "FeaturedRestaurantSimple('";
			// });
			_contents = contents;
			_contents = _contents.replaceAll("FeaturedRestaurantAligned", "FeaturedRestaurantSimple");
			_contents = _contents.replaceAll("CategoryAligned", "CategorySimple");
			_contents = _contents.replaceAll("RestaurantsHeaderAligned", "RestaurantsHeaderSimple");
			_contents = _contents.replaceAll("RestaurantAligned", "RestaurantSimple");

			_flutterTask.write("/lib/main.dart", _contents).then((ok)
			{
				// Start emulator.
				_flutterTask.load("emulator-5554").then((success)
				{
					
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

	void _scrollToPosition()
	{
		_flutterTask.hotReload();
		int idx = _rng.nextInt(_sounds.length);
		_sounds[idx].play();

		setState(() 
		{
			const double offset = 3050.0;
			upFacing = !upFacing;
			if(upFacing)
			{
				arrowIcon = upArrowIcon;
			}
			else
			{
				arrowIcon = downArrowIcon;
			}
			if(upFacing)
			{
				this._offset = new Offset(0.0, 0.0);
			}
			else
			{
				this._offset = new Offset(0.0, offset);
			}
		});
	}

	@override
	Widget build(BuildContext context)
	{
		Size sz = MediaQuery.of(context).size;
		print("BUILD CodeBoxState");
		// double left = sz.width / 3;
		// double top = sz.height / 3;
		double width = sz.width / 2 + 55;
		double height = sz.height / 3 + 51;

		Stack stack = new Stack(
					alignment: const Alignment(0.66, -0.132),
					children: [
						new Container(
							// padding: const EdgeInsets.only(top: 24.0, left: 12.0),
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
											)
										]
									)
						),
						new Container(
							width: width,
							height: height,
							child: new CodeBoxWidget(this._offset)
						)
						],
			);

		return new Scaffold(
			body: new Center(child: stack),
			floatingActionButton: new FloatingActionButton(
				onPressed: _scrollToPosition,
				tooltip: "Scroll To Another Position!",
				child: arrowIcon
			)
		);
	}
}

class WidgetTest extends StatelessWidget
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

	runApp(new WidgetTest());
	// runApp(new MyApp());
}

class MyApp extends StatelessWidget 
{
	// This widget is the root of your application.
	@override
	Widget build(BuildContext context) {
		return new MaterialApp(
			title: 'Flutter Demo',
			theme: new ThemeData(
				// This is the theme of your application.
				//
				// Try running your application with "flutter run". You'll see the
				// application has a blue toolbar. Then, without quitting the app, try
				// changing the primarySwatch below to Colors.green and then invoke
				// "hot reload" (press "r" in the console where you ran "flutter run",
				// or press Run > Flutter Hot Reload in IntelliJ). Notice that the
				// counter didn't reset back to zero; the application is not restarted.
				primarySwatch: Colors.blue,
			),
			home: new MyHomePage(title: 'Flutter Demo Home Page'),
		);
	}
}

class MyHomePage extends StatefulWidget {
	MyHomePage({Key key, this.title}) : super(key: key);

	// This widget is the home page of your application. It is stateful, meaning
	// that it has a State object (defined below) that contains fields that affect
	// how it looks.

	// This class is the configuration for the state. It holds the values (in this
	// case the title) provided by the parent (in this case the App widget) and
	// used by the build method of the State. Fields in a Widget subclass are
	// always marked "final".

	final String title;

	@override
	_MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
	int _counter = 0;
	List<Sound> _sounds;
	FlutterTask _flutterTask = new FlutterTask("~/Projects/BiggerLogo/logo_app");
	Random _rng = new Random();
	bool _ready = false;
	String _contents;
	bool _isReloading;

	handleWebSocketMessage(msg) 
	{
		if(_isReloading || !_ready)
		{
			return;
		}
		_isReloading = true;
		// _contents = _contents.replaceFirstMapped(new RegExp(r"(FeaturedRestaurantSimple)\('"), (Match m)
		// {
		// 	return "FeaturedRestaurantAligned('";
		// });

		if(_contents.indexOf("FeaturedRestaurantSimple") != -1)
		{
			_contents = _contents.replaceAll("FeaturedRestaurantSimple", "FeaturedRestaurantAligned");
		}
		else if(_contents.indexOf("CategorySimple") != -1)
		{
			_contents = _contents.replaceAll("CategorySimple", "CategoryAligned");
		}
		else if(_contents.indexOf("RestaurantsHeaderSimple") != -1)
		{
			_contents = _contents.replaceAll("RestaurantsHeaderSimple", "RestaurantsHeaderAligned");
		}
		else if(_contents.indexOf("RestaurantSimple") != -1)
		{
			_contents = _contents.replaceAll("RestaurantSimple", "RestaurantAligned");
		}
		_flutterTask.write("/lib/main.dart", _contents).then((ok)
		{
			// Start emulator.
			_flutterTask.hotReload().then((ok)
			{
				_isReloading = false;
			});
		});
	}

	_MyHomePageState()
	{
		HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 8080).then(
			(server) async
			{
				print("Serving at ${server.address}:${server.port}");
				await for (var request in server) 
				{
					 if (request.uri.path == '/ws') 
					 {
						// Upgrade a HttpRequest to a WebSocket connection.
						var socket = await WebSocketTransformer.upgrade(request);
						socket.listen(handleWebSocketMessage);
					}
					else
					{
						request.response
						..headers.contentType = new ContentType("text", "plain", charset: "utf-8")
						..write('Hello, world')
						..close();
					}
				}
			});

		_flutterTask.onReady(()
		{
			setState(() 
			{
				_ready = true;
				// Show _contents in monitor.
			});
		});

		// Read contents.
		_flutterTask.read("/lib/main.dart").then((contents)
		{
			// Reset all widgets.
			// _contents = contents.replaceAllMapped(new RegExp(r"(FeaturedRestaurantAligned)\('"), (Match m)
			// {
			// 	return "FeaturedRestaurantSimple('";
			// });
			_contents = contents;
			_contents = _contents.replaceAll("FeaturedRestaurantAligned", "FeaturedRestaurantSimple");
			_contents = _contents.replaceAll("CategoryAligned", "CategorySimple");
			_contents = _contents.replaceAll("RestaurantsHeaderAligned", "RestaurantsHeaderSimple");
			_contents = _contents.replaceAll("RestaurantAligned", "RestaurantSimple");

			_flutterTask.write("/lib/main.dart", _contents).then((ok)
			{
				// Start emulator.
				_flutterTask.load("emulator-5554").then((success)
				{
					
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
	void _incrementCounter() {
		_flutterTask.hotReload();
		int idx = _rng.nextInt(_sounds.length);
		_sounds[idx].play();
		// WebSocket.connect('ws://127.0.0.1:8080/ws').then((socket)
		// {
		// 	socket.add('Hello, World! $idx');
		// });
  		
		setState(() {
			// This call to setState tells the Flutter framework that something has
			// changed in this State, which causes it to rerun the build method below
			// so that the display can reflect the updated values. If we changed
			// _counter without calling setState(), then the build method would not be
			// called again, and so nothing would appear to happen.
			_counter++;
		});
	}

	@override
	Widget build(BuildContext context) {
		// This method is rerun every time setState is called, for instance as done
		// by the _incrementCounter method above.
		//
		// The Flutter framework has been optimized to make rerunning build methods
		// fast, so that you can just rebuild anything that needs updating rather
		// than having to individually change instances of widgets.
		return new Scaffold(
			appBar: new AppBar(
				// Here we take the value from the MyHomePage object that was created by
				// the App.build method, and use it to set our appbar title.
				title: new Text(widget.title),
			),
			body: new Center(
				// Center is a layout widget. It takes a single child and positions it
				// in the middle of the parent.
				child: new Column(
					// Column is also layout widget. It takes a list of children and
					// arranges them vertically. By default, it sizes itself to fit its
					// children horizontally, and tries to be as tall as its parent.
					//
					// Invoke "debug paint" (press "p" in the console where you ran
					// "flutter run", or select "Toggle Debug Paint" from the Flutter tool
					// window in IntelliJ) to see the wireframe for each widget.
					//
					// Column has various properties to control how it sizes itself and
					// how it positions its children. Here we use mainAxisAlignment to
					// center the children vertically; the main axis here is the vertical
					// axis because Columns are vertical (the cross axis would be
					// horizontal).
					mainAxisAlignment: MainAxisAlignment.center,
					children: <Widget>[
						new Text(
							'You have pushed the button this many times:',
						),
						new Text(
							'$_counter',
							style: Theme.of(context).textTheme.display1,
						),
					],
				),
			),
			floatingActionButton: _ready ? new FloatingActionButton(
				onPressed: _incrementCounter,
				tooltip: 'Increment',
				child: new Icon(Icons.add),
			) : null, // This trailing comma makes auto-formatting nicer for build methods.
		);
	}
}
