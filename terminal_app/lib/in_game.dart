import 'package:flutter/widgets.dart';
import "command_panel.dart";
import "players_widget.dart";
import "panel_button.dart";
import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flutter/rendering.dart";
import "game_controls/game_slider.dart";
import "game_controls/game_radial.dart";

class InGame extends StatelessWidget
{
    final VoidCallback _onReady;
    final VoidCallback _onStart;
    final VoidCallback _onRetry;
    final double _opacity;
	final bool isOver;

    const InGame(this._opacity, this._onReady, this._onStart, this._onRetry, {  this.isOver: false , Key key } ) : super(key: key);

    @override
    Widget build(BuildContext context)
    {
		print("BUILD: $isOver");
		return new Expanded(
					child:new Opacity(
                    	opacity: _opacity,
						child:new Container(
							margin:new EdgeInsets.only(top:43.0), 
							child:
							this.isOver ? 
							new GameOver(_onRetry) :
							new ControlGrid(
								children:<Widget>[
									new TitledCommandPanel("HEIGHT", new GameSlider(), isExpanded: true),
									new TitledCommandPanel("MARGIN", new GameRadial(), isExpanded: true),
									new TitledCommandPanel("TEST", new Container(), isExpanded: true),
								]
							)
						)
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
		// FIXME: overflows for smaller layouts
		RenderBox child = firstChild;
		const double padding = 50.0;
		const double numColumns = 2.0;
		final double childWidth = (size.width - (padding*(numColumns-1)))/numColumns;
		final double rowHeight = childWidth;

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

class GameOver extends StatelessWidget
{
	final VoidCallback _onRetry;

	GameOver(this._onRetry, {Key key}) : super(key: key);

	@override
	Widget build(BuildContext context) 
	{
		return new Center(
				child: new Column(
					children: 
					[
						new Expanded(child: new Container()),
						new Text("GAME\nOVER", 
							textAlign: TextAlign.center,
							style: new TextStyle(color: new Color.fromARGB(255, 167, 230, 237), 
								fontFamily: "RalewayDots",
								fontWeight: FontWeight.w100,
								fontSize: 144.0, 
								decoration: TextDecoration.none
							)
						),
						new Container(
							width: 274.0,
							child: new PanelButton("Try Again", 59.0, 18.0, 1.3, const EdgeInsets.only(top:95.0, bottom: 90.0), _onRetry)
						)
					],
				)
		);
	}
	
}