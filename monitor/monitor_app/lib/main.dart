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
import "package:nima/nima_flutter.dart";
import "package:nima/animation/actor_animation.dart";
import "package:flutter/animation.dart";
import "dart:ui" as ui;
import "package:flutter/scheduler.dart";

Future<String> loadFileAssets(String filename) async
{
	return await rootBundle.loadString("assets/files/$filename");
}

class CodeBoxWidget extends LeafRenderObjectWidget
{
	final Offset _offset;
	final String _contents;

	CodeBoxWidget(this._offset, this._contents, {Key key}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) => new TextRenderObject(screenOffset: this._offset,fontSize: 16.0);

	@override
	void updateRenderObject(BuildContext context, TextRenderObject renderObject) 
	{
		renderObject.text = this._contents;
		renderObject.offset = this._offset;
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
		arrowIcon = new Icon(Icons.arrow_downward)
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
		const double offset = 1000.0;
		_flutterTask.hotReload();
		int idx = _rng.nextInt(_sounds.length);
		_sounds[idx].play();

		setState(() 
		{
			upFacing = !upFacing;
			if(upFacing)
			{
				arrowIcon = downArrowIcon;
			}
			else
			{
				arrowIcon = upArrowIcon;
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
		// TODO: revisit sizes and alignments
		double width = 1050.0;//sz.width / 2 + 55;
		double height = 570.0;//sz.height / 3 + 51;

		Stack stack = new Stack(
					alignment: const Alignment(0.6575, -0.22),
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
											),
											new NimaWidget("/assets/nima/NPC1/NPC1")
										]
									)
						),
						new Container(
							width: width,
							height: height,
							child: new CodeBoxWidget(this._offset, this._contents)
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
		final double t = timeStamp.inMicroseconds / Duration.MICROSECONDS_PER_MILLISECOND / 1000.0;
		
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
				_animation = _actor.getAnimation("Upset");
				_animationTime = 0.0;
				markNeedsPaint();
			});
		}
		super.markNeedsPaint();
	}
}
