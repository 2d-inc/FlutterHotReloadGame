import "package:flutter/material.dart";

import "../game.dart";
import "../game_provider.dart";
import "../widgets/panel_button.dart";
import "game_command_widget.dart";

/// This Game Control will show either two or three buttons in the [InGame] grid.
/// Its passed in a [List<String>] for the [PanelButton]s that are built, and a [String] 
/// so that the server can identify the command that's been issued when the button is pressed.
/// Lastly a flag [isTall] is used to build the widget appropriately.
class GameBinaryButton extends StatelessWidget implements GameCommand
{
    static const EdgeInsets horizontalPlacement = const EdgeInsets.only(right:10.0, bottom: 10.0);
    static const EdgeInsets verticalPlacement = const EdgeInsets.only(bottom: 10.0);

	final List<String> _labels;
	final String taskType;
    /// This flag isn't null because it can be changed in [InGame.buildGrid()], and thus 
    /// cannot be finalized on construction.
	bool isTall;

	GameBinaryButton.make(this.taskType, Map params, {this.isTall: false}) : _labels = new List<String>(params['buttons'].length)
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
        /// This object relies on the [Game] class only for a the [Game.issueCommand()] callback.
        Game game = GameProvider.of(context);
		bool hasThree = _labels.length > 2;
		List<Widget> buttons = [];
		for(int i = 0; i < _labels.length; i++)
		{
			buttons.add(
				new Expanded(
					child:
						new PanelButton(_labels[i], 16.0, 1.1, 
							!hasThree ? horizontalPlacement : (isTall ? verticalPlacement : (i < 1) ? horizontalPlacement : verticalPlacement),
					() 
					{
						game.issueCommand(taskType, i);
					}, isAccented: true)
				)
			);
		}
		if(!hasThree)
		{
            /// If the widget is made of two components, lay them out in a [Row].
			return new Row(children: buttons);
		}
		else if(isTall)
		{
            /// If this widget has enough space to grow, place the buttons in a [Column].
			return new Column(children:buttons);
		}
		else /// !isTall && hasThree
		{
            /// If there's not enough space vertically, and there are three buttons to be displayed,
            /// use one [Column] split into two shorter [Row]s.
			return new Column(children:
			[
				new Expanded(child:new Row(children: buttons.sublist(0, 2))),
				new Expanded(child:new Row(children: [buttons.last]))
			]);
		}
	}
}
