import 'package:flutter/material.dart';
import "panel_button.dart";

typedef void StringCallback(String msg);
final RegExp reg = new RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))");
final Function matchFunc = (Match match) => "${match[1]},";

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
							width: 274.0,
							child: new PanelButton("ENTER TEAM INITIALS", 18.0, 1.3, const EdgeInsets.only(top:40.0), () => showDialog(
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
							isEnabled: _canEnterInitials, 
							height:60.0)
						),
						new Container(
							width: 274.0,
							child: new PanelButton("TRY AGAIN", 18.0, 1.3, const EdgeInsets.only(top:10.0), _onRetry, height:60.0)
						)
					],
				)
		);
	}	
}