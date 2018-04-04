import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flutter/rendering.dart";
import "package:web_socket_channel/web_socket_channel.dart";
import "package:web_socket_channel/io.dart";
import "dart:io";
import "command_panel.dart";
import "players_widget.dart";

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

class _MyHomePageState extends State<MyHomePage> 
{	
	List<Widget> _buttonList;

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
		// TODO:
	}

	@override
	Widget build(BuildContext context) 
	{
		final double DPR = MediaQuery.of(context).devicePixelRatio;

		return new Container(
			decoration:new BoxDecoration(color:Colors.white),
			child:new Row(
				children: <Widget>[
					new Container(
						width: MediaQuery.of(context).size.width * 0.66
					),
					new Expanded(
						child:new Container(
							padding: new EdgeInsets.all(12.0 * DPR),
							decoration:new BoxDecoration(color:Colors.black),
							child: new Container(
								decoration: new BoxDecoration(border: new Border.all(color: const Color.fromARGB(127, 72, 196, 206)), borderRadius: new BorderRadius.circular(3.0)),
								padding: new EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 6.0),
								child: new Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: 
									[
										// Title Row
										new Row(children: 
											[	
												new Text("SYSTEM ONLINE", style: new TextStyle(color: new Color.fromARGB(255, 167, 230, 237), fontFamily: "Inconsolata", fontSize: 6.0, decoration: TextDecoration.none, letterSpacing: 0.4)),
												new Text(" > MILESTONE INITIATED", style: new TextStyle(color: new Color.fromARGB(255, 86, 234, 246), fontFamily: "Inconsolata", fontSize: 6.0, decoration: TextDecoration.none, letterSpacing: 0.5))
											]
										),
										new Row(children: [ new Expanded(child: new Container(margin: new EdgeInsets.only(top:5.0), color: const Color.fromARGB(77, 167, 230, 237), height: 1.0)) ]),
										new Row(children: [ new Expanded(child: new Container(margin: new EdgeInsets.only(top:5.0), color: const Color.fromARGB(77, 167, 230, 237), height: 1.0)) ]), 
										// Players Row
										new CommandPanel(new PlayerListWidget()),
										// Fill the middle space
										new Expanded(child: new Container()),
										// Buttons
										new Column(
											children:
											[
												new GestureDetector(
													onTap: _handleReady,
													child: new Container(
														decoration: new BoxDecoration(borderRadius: new BorderRadius.circular(3.0), color: const Color.fromARGB(255, 22, 75, 81)),
														child: new Container(
															height: 59.0,
															alignment: Alignment.center,
															child: new Text("SET TO READY", style: const TextStyle(color: const Color.fromARGB(255, 167, 230, 237), fontFamily: "Inconsolata", fontWeight: FontWeight.bold, fontSize: 18.0, decoration: TextDecoration.none, letterSpacing: 1.3))
														)
													)
												),
												new GestureDetector(
													onTap: _handleStart,
													child: new Container(
														margin: const EdgeInsets.only(top: 10.0),
														decoration: new BoxDecoration(borderRadius: new BorderRadius.circular(3.0), color: const Color.fromARGB(204, 9, 45, 51)),
														child: new Container(
															height: 59.0,
															alignment: Alignment.center,
															child: new Text("START", style: const TextStyle(color: const Color.fromARGB(51, 167, 230, 237), fontFamily: "Inconsolata", fontWeight: FontWeight.bold, fontSize: 18.0, decoration: TextDecoration.none, letterSpacing: 1.3))
														)
													)
												)
											],
										),
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
											// child:new ControlGrid(
											// 	children:<Widget>[
											// 		new GestureDetector(onTap: _handleTap, child:new Container(decoration:new BoxDecoration(color:Colors.red))),
											// 		new GestureDetector(onTap: _handleTap, child:new Container(decoration:new BoxDecoration(color:Colors.green))),
											// 		new GestureDetector(onTap: _handleTap, child:new Container(decoration:new BoxDecoration(color:Colors.blue))),
											// 		new Container(
											// 			decoration: new BoxDecoration(borderRadius: new BorderRadius.circular(3.0), color: const Color.fromARGB(255, 22, 75, 81)),
											// 			child: new Container(
											// 				alignment: Alignment.center,
											// 				child: new Text("SET TO READY", style: const TextStyle(color: const Color.fromARGB(255, 167, 230, 237), fontFamily: "Inconsolata", fontWeight: FontWeight.bold, fontSize: 28.0, decoration: TextDecoration.none, letterSpacing: 1.3))
											// 			)
											// 		)
											// 	]
											// )
	addButton(Widget w)
	{
		_buttonList.add(w);
	}

	get children => _buttonList;
}

class ControlGrid extends MultiChildRenderObjectWidget
{
	ControlGrid({
    	Key key,
		List<Widget> children: const <Widget>[],
	}) : super(key: key, children: children);

	@override
	RenderControlGrid createRenderObject(BuildContext context) 
	{
		return new RenderControlGrid();
	}

	@override
	void updateRenderObject(BuildContext context, covariant RenderControlGrid renderObject) 
	{
	}

	@override
	void debugFillProperties(DiagnosticPropertiesBuilder description) 
	{
		super.debugFillProperties(description);
	}
}

class ControlGridParentData extends ContainerBoxParentData<RenderBox> 
{

}
/*class Flexible extends ParentDataWidget<Flex> {*/
class RenderControlGrid extends RenderBox with ContainerRenderObjectMixin<RenderBox, ControlGridParentData>, RenderBoxContainerDefaultsMixin<RenderBox, ControlGridParentData> 
{
	 @override
	bool get sizedByParent => true;

	@override
	void performResize() 
	{
		size = constraints.biggest;
	}

	@override
	void setupParentData(RenderBox child) 
	{
    	if (child.parentData is! ControlGridParentData)
		{
			child.parentData = new ControlGridParentData();
		}
	}
	@override
  	void performLayout() 
	{
		// For now, just place them in a grid. Later we need to use MaxRects to figure out the best layout as some cells will be double height.
		RenderBox child = firstChild;
		const double padding = 50.0;
		const double numColumns = 2.0;
		final double childWidth = (size.width - (padding*(numColumns-1)))/numColumns;
		final double rowHeight = childWidth/2.0;

		int idx = 0;
    	while (child != null) 
		{
			Constraints constraints = new BoxConstraints(minWidth: childWidth, maxWidth: childWidth, minHeight:rowHeight, maxHeight:rowHeight);
			child.layout(constraints, parentUsesSize: true);
			final ControlGridParentData childParentData = child.parentData;
			childParentData.offset = new Offset((idx%numColumns) * (childWidth+padding), (idx/numColumns).floor()*(rowHeight+padding));
        	child = childParentData.nextSibling;
			idx++;
		}
	}

	 @override
	bool hitTestChildren(HitTestResult result, { Offset position }) 
	{
		return defaultHitTestChildren(result, position: position);
	}

	@override
	void paint(PaintingContext context, Offset offset)
	{
		//context.canvas.drawRect(offset & size, new Paint()..color = new Color.fromARGB(255, 125, 152, 165));
		defaultPaint(context, offset);
	}
}