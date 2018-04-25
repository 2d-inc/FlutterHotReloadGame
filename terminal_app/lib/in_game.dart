import "dart:math";
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import "command_panel.dart";
import "panel_button.dart";
import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flutter/rendering.dart";
import "game_controls/game_slider.dart";
import "game_controls/game_radial.dart";
import "game_controls/game_command_widget.dart";

typedef void StringCallback(String msg);
final RegExp reg = new RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))");
final Function matchFunc = (Match match) => "${match[1]},";

class InGame extends StatelessWidget
{
    final VoidCallback _onRetry;
    final StringCallback _onInitialsSet;
    final double _opacity;
	final bool isOver;
	final bool hasWon;
	final bool canEnterInitials;
	final List _gridDescription;
	final IssueCommandCallback _issueCommand;
	final int _seed;	
	final int score;

	static const Map gameWidgetsMap = const {
		"GameBinaryButton" : GameBinaryButton,
		"GameSlider": GameSlider,
		"GameRadial": GameRadial,
	};

    const InGame(this._opacity, this._onRetry, this._gridDescription, this._issueCommand, this._seed, this._onInitialsSet, { this.isOver: false, this.hasWon: false, this.canEnterInitials: false, this.score: 0, Key key } ) : super(key: key);

	Widget buildGrid(BuildContext context, BoxConstraints constraints)
	{
		// Decide which elements have the highest priority
		PriorityQueue pq = new PriorityQueue((e1, e2) {
			int p1 = e1['priority'];
			int p2 = e2['priority'];
			return p2-p1;
		});
		for(int i = 0; i < _gridDescription.length; i++)
		{
			var description = _gridDescription[i % _gridDescription.length];
			int priority = 0;
			String type = description['type'];
			String name = description['title'];
			String taskType = description["taskType"];
			Widget w;
			
			switch(type)
			{
				case "GameBinaryButton":
					Map d = description as Map;
					List buttons = d['buttons'];
					if(buttons.length > 2)
					{
						priority = 10;
					}
					else
					{
						priority = 1;
					}
					w = new GameBinaryButton.make(_issueCommand, taskType, description);
					break;
				case "GameSlider":
					w = new GameSlider.make(_issueCommand, taskType, description);
					priority = 1;
					break;
				case "GameRadial":
					w = new GameRadial.make(_issueCommand, taskType, description);
					priority = 5;
					break;

			}
			pq.add({
				"widget": w,
				"name": name,
				"priority": priority
			});
		}

		const int padding = 50;
		final Size gridSize = constraints.biggest;
		final double cellWidth = (gridSize.width - padding) / 2;
		final double cellHeight = (gridSize.height - padding * 2) / 3;
		final double doubleCellHeight = cellHeight * 2 + padding;

		int numCols = 2;
		int numRows = 3;
		double left = 0.0;
		double top = 0.0;
		// Generate the list of widget positions
		List<Offset> positions = <Offset>[];
		for(int i = 0; i < numCols; i++)
		{
			top = 0.0;
			left = (cellWidth + padding)*i;

			for(int j = 0; j < numRows; j++)
			{
				top = (cellHeight + padding) * j;
				positions.add(new Offset(left, top));
			}
		}
		List<Widget> grid = [];
		Random rand = new Random(_seed);
		int randCol = rand.nextInt(numCols);
		int randRow = rand.nextInt(numRows - 1);
		int biggerIndex = randCol * numRows + randRow;
		Offset bigStart = positions.removeAt(biggerIndex);
		positions.removeAt(biggerIndex); // Remove also the following element since we're occupying two rows
		var biggest = pq.removeFirst();
		grid.add(new Positioned(
			width: cellWidth,
			height: doubleCellHeight,
			left: bigStart.dx,
			top: bigStart.dy,
			child: new TitledCommandPanel(biggest['name'], biggest['widget'], isExpanded: true)
		));

		while(pq.isNotEmpty)
		{
			var next = pq.removeFirst();
			Offset nextPosition = positions.removeAt(0);
			Widget w = next['widget'];
			if(w is GameRadial)
			{
				w = new GameSlider.fromRadial(w);
			}
			grid.add(new Positioned(
				width: cellWidth,
				height: cellHeight,
				left: nextPosition.dx,
				top: nextPosition.dy,
				child: new TitledCommandPanel(next['name'], w, isExpanded: true)
			));
		}

		return new Stack(children: grid);
	}

    @override
    Widget build(BuildContext context)
    {
		return new Expanded(
					child:new Opacity(
                    	opacity: _opacity,
						child:new Container(
							margin:new EdgeInsets.only(top:43.0), 
							child:
							this.hasWon ? new HighScore(_onRetry, _onInitialsSet, score, canEnterInitials) :
							this.isOver ? new GameOver(_onRetry) : new LayoutBuilder(builder: buildGrid)
							// new ControlGrid(
							// 	children: grid
							// )
						)
					)
				);
    }   
}

class GameBinaryButton extends StatelessWidget implements GameCommand
{
	// TODO: final List<VoidCallback> _callbacks;
	final List<String> _labels;
	final String taskType;
	final IssueCommandCallback issueCommand;

	//GameBinaryButton(this._labels, {Key key}) : super(key: key);

	GameBinaryButton.make(this.issueCommand, this.taskType, Map params) : _labels = new List<String>(params['buttons'].length)
	{
		List l = params['buttons'];
		for(int i = 0; i < l.length; i++)
		{
			_labels[i] = (l[i] as String);
		}
	}

	@override
	Widget build(BuildContext context)
	{
		bool isTall = _labels.length > 2;
		List<Widget> buttons = [];
		for(int i = 0; i < _labels.length; i++)
		{
			buttons.add(
				new Expanded(
					child:
						new PanelButton(_labels[i], 16.0, 1.1, 
							isTall ? const EdgeInsets.only(bottom: 10.0) : const EdgeInsets.only(right:10.0, bottom: 10.0), 
					() 
					{
						issueCommand(taskType, i);
						/* TODO: */
					}, isAccented: true)
				)
			);
		}

		return buttons.length > 2 ? new Column(children: buttons) : Row(children: buttons);
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
		final double childWidth = (size.height - (padding*(numColumns-1)))/numColumns;
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
							child: new PanelButton("Try Again", 18.0, 1.3, const EdgeInsets.only(top:95.0, bottom: 90.0), _onRetry)
						)
					],
				)
		);
	}	
}

class HighScore extends StatelessWidget
{
	final VoidCallback _onRetry;
	final StringCallback _onInitialsSet;
	final String _score;
	final TextEditingController _initialsController = new TextEditingController();
	final bool _canEnterInitials;

	HighScore(this._onRetry, this._onInitialsSet, int s, this._canEnterInitials) : _score = s.toString().replaceAllMapped(reg, matchFunc);

	@override
	Widget build(BuildContext context) 
	{
		return new Center(
				child: new Column(
					children: 
					[
						new Container(
							margin: new EdgeInsets.only(top: 68.0),
							child:new Text("HIGH\nSCORE!", 
								textAlign: TextAlign.center,
								style: new TextStyle(color: new Color.fromARGB(255, 167, 230, 237), 
									fontFamily: "RalewayDots",
									fontWeight: FontWeight.w100,
									fontSize: 144.0, 
									height: 0.8,
									decoration: TextDecoration.none
								)
							)
						),
						new Row(children: [ new Expanded(child: new Container(margin: new EdgeInsets.only(top:30.0, left:73.0, right:73.0), color: Colors.white, height: 2.0)) ]),
						new Container(
							height: 105.0,
							child:new Center(
								child: new Text(
									_score,
									style: new TextStyle(
										color: Colors.white,
										fontFamily: "Inconsolata",
										fontWeight: FontWeight.normal,
										fontSize: 36.0,
										height: 42.0/36.0,
										decoration: TextDecoration.none
									),
								)
							)
						),
						new Row(children: [ new Expanded(child: new Container(margin: new EdgeInsets.only(left:73.0, right:73.0, top: 10.0), color: Colors.white, height: 2.0)) ]),
						new Container(
							width: 274.0,
							child: new PanelButton("ENTER YOUR INITIALS", 18.0, 1.3, const EdgeInsets.only(top:40.0), () => showDialog(
								context: context,
								builder: (_) => new AlertDialog(
									title: new Text("INITIALS:"),
									content: new TextFormField(
										controller: _initialsController,
										decoration: new InputDecoration(hintText: "___"),
										autofocus: true,
										maxLength: 3,
										maxLines: 1
									),
									actions:
									[
										new FlatButton(
											child: new Text("OK"),
											onPressed: ()
											{
												String initials = _initialsController.text;
												if(initials.length == 3)
												{
													_onInitialsSet(initials);
													Navigator.of(context).pop();
												}
											},
										)
									]
								)
							), 
							isAccented: _canEnterInitials,
							isEnabled: _canEnterInitials)
						),
						new Container(
							width: 274.0,
							child: new PanelButton("TRY AGAIN", 18.0, 1.3, const EdgeInsets.only(top:10.0), _onRetry)
						)
					],
				)
		);
	}	
}