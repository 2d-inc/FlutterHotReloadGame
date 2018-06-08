import "package:flutter/material.dart";

import "game/game.dart";
import "game/game_provider.dart";
import "game_controls/game_command_widget.dart";
import "panel_button.dart";

class GameBinaryButton extends StatelessWidget implements GameCommand
{
	final List<String> _labels;
	final String taskType;
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
        Game game = GameProvider.of(context);
		bool hasThree = _labels.length > 2;
		List<Widget> buttons = [];
		const EdgeInsets horizontalPlacement = const EdgeInsets.only(right:10.0, bottom: 10.0);
		const EdgeInsets verticalPlacement = const EdgeInsets.only(bottom: 10.0);
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
			return new Row(children: buttons);
		}
		else if(isTall)
		{
			return new Column(children:buttons);
		}
		else //!isTall && hasThree
		{
			return new Column(children:
			[
				new Expanded(child:new Row(children: buttons.sublist(0, 2))),
				new Expanded(child:new Row(children: [buttons.last]))
			]);
		}
	}
}
