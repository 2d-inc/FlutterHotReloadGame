import 'package:flutter/material.dart';
import "package:flutter/foundation.dart";
import "package:flutter/rendering.dart";

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
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

class MyHomePage extends StatefulWidget 
{
	MyHomePage({Key key, this.title}) : super(key: key);
	final String title;

	@override
	_MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> 
{
	void _handleTap()
	{
		print("TAP!");
	}

	@override
	Widget build(BuildContext context) 
	{
		//new GestureDetector(onTap: _handleTap, child:
		return new Container(
			decoration:new BoxDecoration(color:Colors.white),
			child:new Row(
				children: <Widget>[
					new Container(
						width:500.0
					),
					new Expanded(
						child:new Container(
							padding:const EdgeInsets.fromLTRB(50.0, 50.0, 50.0, 50.0),
							decoration:new BoxDecoration(color:Colors.black),
							child:new Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: <Widget>[
									new Container(
										padding:const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 50.0),
										child:new Text("Terminal App", style:const TextStyle(fontSize:12.0,color:Colors.white, decoration: TextDecoration.none))
									),
									new Expanded(
										child:new ControlGrid(
											children:<Widget>[
												new GestureDetector(onTap: _handleTap, child:new Container(decoration:new BoxDecoration(color:Colors.red))),
												new GestureDetector(onTap: _handleTap, child:new Container(decoration:new BoxDecoration(color:Colors.green))),
												new GestureDetector(onTap: _handleTap, child:new Container(decoration:new BoxDecoration(color:Colors.blue))),
											]
										)
									)
								]
							)
						)
					)
				],
			)
		);
	}
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