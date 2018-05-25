import "package:flutter/material.dart";
import "panel_button.dart";

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
						new Container(
							width: 274.0,
							child: new PanelButton("Try Again", 18.0, 1.3, const EdgeInsets.only(top:95.0, bottom: 90.0), _onRetry, height:60.0)
						)
					],
				)
		);
	}	
}