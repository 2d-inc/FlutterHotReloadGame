import "dart:math";

import 'package:collection/collection.dart';
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import 'package:flutter/widgets.dart';

import "../blocs/game_stats_bloc.dart";
import "../blocs/in_game_bloc.dart";
import "../controls/game_buttons.dart";
import "../controls/game_radial.dart";
import "../controls/game_slider.dart";
import "../game.dart";
import "../game_provider.dart";
import "enter_initials.dart";
import "game_over.dart";
import "game_over_stats.dart";
import "titled_command_panel.dart";

typedef void StringCallback(String msg);

/// This Widget is displayed when a new game begins. The server assigns the Controls that'll make up the grid
/// with [GameBinaryButton]s, [GameSlider]s and/or [GameRadial]s. The [buildGrid()] function performs some 
/// calculations to lay these elements out properly, respecting the space constraints available to this element.
/// Once a game is over, the grid is replaced by the [GameStats] widget.
class InGame extends StatelessWidget
{
    final List _gridDescription = [];

    /// Callback that is used for the [PanelButton] to go back to the lobby. 
    /// This is piped directly from the [_TerminalState]
    final VoidCallback _onRetry;
    /// This field animates the opacity for the current widget so it can fade in and out during transitions.
    final double _opacity;
    /// Seed that's reset every time a game starts. Also comes from [_TerminalState].
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

    /// This function builds a 3x2 grid of elements. 
    /// In any game there'll be at most 5 elements in the grid, thus one widget
    /// is going to occupy two vertical cells of the grid.
	Widget buildGrid(BuildContext context, BoxConstraints constraints)
	{
		PriorityQueue pq = new PriorityQueue(
		/// Define how the priority is chosen when building the commands grid.
        (e1, e2) {
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
			
            /// Define the priority of the given elemtns as follows:
            /// 1. 3 Buttons Control
            /// 2. Radial control
            /// 3. Game Slider & 2 Buttons Control
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
        /// Get the size of this Box by querying its constraints.
        /// Then define the the constants needed to build the actual [Widget]s
		final Size gridSize = constraints.biggest;
		final double cellWidth = (gridSize.width - padding) / 2;
		final double cellHeight = (gridSize.height - padding * 2) / 3;
		final double doubleCellHeight = cellHeight * 2 + padding;

		int numCols = 2;
		int numRows = 3;
		double left = 0.0;
		double top = 0.0;
		/// Generate the list of widget positions starting from the top-left corner.
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
        /// Start by placing the highest priority widget in a random 'double' vertical cell.
		Random rand = new Random(_seed);
		int randCol = rand.nextInt(numCols);
        /// Can't place a 'double' vertical widget in the last row.
		int randRow = rand.nextInt(numRows - 1);
		int biggerIndex = randCol * numRows + randRow;
        /// Extract the first position from the queue.
        /// Remove also the following element since we're occupying two rows.
		Offset bigStart = positions.removeAt(biggerIndex);
		positions.removeAt(biggerIndex); 
		var biggest = pq.removeFirst();
		Widget bw = biggest['widget'];
		if(bw is GameBinaryButton)
		{
            /// If the highest priority widget in question is a [GameBinaryButton],
            /// by passing it this flag, it'll be able to draw and occupy its vertical space fully.
			bw.isTall = true;
		}
		grid.add(new Positioned(
			width: cellWidth,
			height: doubleCellHeight,
			left: bigStart.dx,
			top: bigStart.dy,
			child: new TitledCommandPanel(biggest['name'], bw, isExpanded: true)
		));

        /// Iterate until the queue and all the widgets in the [gridDescription] have been placed
        /// in the available spots.
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
            /// By clearing and re-inserting all the elements, the list can be final
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
                    /// Once the game is over, the game screen will display the stats.
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
                        status.hasWon ? new EnterInitials(_onRetry) : new GameOver(_onRetry)
                    ])
                    /// If the game has just started, build the commands on the screen.
                    :  new LayoutBuilder(builder: buildGrid)
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