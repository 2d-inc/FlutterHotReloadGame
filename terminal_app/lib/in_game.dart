import "dart:math";
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import "command_panel.dart";
import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flutter/rendering.dart";
import "game_controls/game_slider.dart";
import "game_controls/game_radial.dart";
import "game_controls/game_command_widget.dart";
import "game_over_stats.dart";
import "high_score.dart";
import "game_over.dart";
import "game_buttons.dart";
import "game/game_provider.dart";
import "game/game.dart";
import "game/blocs/in_game_bloc.dart";
import "game/blocs/game_stats_bloc.dart";

typedef void StringCallback(String msg);

class InGame extends StatelessWidget
{
    final List _gridDescription = [];

    final VoidCallback _onRetry;
    final double _opacity;
	final int _seed;

	static const Map gameWidgetsMap = const {
		"GameBinaryButton" : GameBinaryButton,
		"GameSlider": GameSlider,
		"GameRadial": GameRadial,
	};

    InGame(
        this._opacity, 
        this._onRetry, 
        this._seed, 
        { Key key } ) : super(key: key);

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
					w = new GameBinaryButton.make(taskType, description);
					break;
				case "GameSlider":
					w = new GameSlider.make(taskType, description);
					priority = 1;
					break;
				case "GameRadial":
					w = new GameRadial.make(taskType, description);
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
		Widget bw = biggest['widget'];
		if(bw is GameBinaryButton)
		{
			bw.isTall = true;
		}
		grid.add(new Positioned(
			width: cellWidth,
			height: doubleCellHeight,
			left: bigStart.dx,
			top: bigStart.dy,
			child: new TitledCommandPanel(biggest['name'], bw, isExpanded: true)
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

    set gridDescription(List gd)
    {
        if(gd != _gridDescription)
        {
            // Keep the list final
            _gridDescription.clear();
            _gridDescription.addAll(gd);
        }
    }

    Widget buildInGame(BuildContext context, AsyncSnapshot<InGameStatus> snapshot)
    {
        Game game = GameProvider.of(context);
        InGameStatus status = snapshot.data;
        if(status == null)
        {
            return Container();
        }
        this.gridDescription = status.gridDescription;
        return new Container
        (
            margin:status.isOver ? new EdgeInsets.all(80.0) : new EdgeInsets.only(top:43.0), 
            child:
                status.isOver ? 
                    new Column( children:<Widget>
                    [
                        new Expanded(child:
                            new StreamBuilder(
                                stream: game.gameStatsBloc.stream,
                                builder: (BuildContext ctx, AsyncSnapshot<GameStatistics> statsSnapshot)
                                {
                                    GameStatistics gs = statsSnapshot.data;
                                    if(gs == null)
                                    {
                                        return Container();
                                    }
                                    return new GameStats(
                                        gs.time, 
                                        gs.progress, 
                                        gs.score, 
                                        gs.lives, 
                                        gs.rank, 
                                        gs.finalScore, 
                                        gs.lifeScore
                                    );
                                }
                            )
                        ),
                        status.hasWon ? new HighScore(_onRetry) : new GameOver(_onRetry)
                    ])
                    : 
                    new LayoutBuilder(builder: buildGrid)
        );
    }

    @override
    Widget build(BuildContext context)
    {
        Game game = GameProvider.of(context);
		return new Expanded(
					child:new Opacity(
                    	opacity: _opacity,
						child:
                        new StreamBuilder(
                            stream: game.inGameBloc.stream,
                            builder: buildInGame
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