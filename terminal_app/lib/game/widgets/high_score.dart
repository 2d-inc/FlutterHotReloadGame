import 'package:flutter/material.dart';

import "../blocs/game_stats_bloc.dart";
import "../game.dart";
import "../game_provider.dart";
import "panel_button.dart";

typedef void StringCallback(String msg);
final RegExp reg = new RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))");
final Function matchFunc = (Match match) => "${match[1]},";

class HighScore extends StatelessWidget
{
	final VoidCallback _onRetry;
	final TextEditingController _initialsController = new TextEditingController();

	HighScore(this._onRetry);

	@override
	Widget build(BuildContext context) 
	{
        final Game game = GameProvider.of(context);
		return new Center(
				child: new Column(
					children: 
					[
                        new StreamBuilder(
                            stream: game.gameStatsBloc.stream,
                            builder: (BuildContext ctx, AsyncSnapshot<GameStatistics> snapshot)
                            {
                                if(snapshot.data == null)
                                {
                                    return Container();
                                }
                                bool canEnterInitials = snapshot.data.initials.isEmpty;
                                return new Container(
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
                                                            game.client.initials = initials;
                                                            Navigator.of(context).pop();
                                                        }
                                                    },
                                                )
                                            ]
                                        )
                                    ), 
                                    isAccented: canEnterInitials,
                                    isEnabled: canEnterInitials, 
                                    height:60.0)
                                );
                            }
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