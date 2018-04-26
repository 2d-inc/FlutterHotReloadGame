import 'package:flutter/widgets.dart';
import "command_panel.dart";
import "players_widget.dart";
import "panel_button.dart";
import "game_controls/game_colors.dart";

class LobbyWidget extends StatelessWidget
{
    final VoidCallback _onReady;
    final VoidCallback _onStart;
    final double _opacity;
    final bool _ready;
    final List<bool> _arePlayersReady;
    final bool canBeReady;
    final bool markedStart;

    const LobbyWidget(this.canBeReady, this._ready, this.markedStart, this._arePlayersReady, this._opacity, this._onReady, this._onStart, { Key key  } ) : super(key: key);

    @override
    Widget build(BuildContext context)
    {
        int readyNum = 0;
        for(var p in _arePlayersReady)
        {
            if(p)
            {
                readyNum++;
            }
        }

        bool canStart = _ready && readyNum > 1;
        return new Expanded(
                child: new Opacity(
                    opacity: _opacity,
                    child: new Column(
                        mainAxisSize: MainAxisSize.max,
                        children: 
                        [
                            // Players Row
                            new CommandPanel(new PlayerListWidget(!canBeReady, this._arePlayersReady)),
                            // Filler
                            new Expanded(child: new Container()),
                            // Buttons
                            markedStart ? 
                                new Container(
                                    margin: new EdgeInsets.only(bottom:60.0, left:60.0, right:60.0),
                                    child:new Text("WAITING FOR ALL PLAYERS TO START", 
                                    textAlign:TextAlign.center,
                                    style: new TextStyle(
                                        color: GameColors.buttonEnabledText,
                                        fontFamily: "Inconsolata", 
                                        fontWeight: FontWeight.w700, 
                                        fontSize: 20.0, 
                                        height: 1.2,
                                        decoration: TextDecoration.none, 
                                        letterSpacing: 1.3
                                    )
                                )
                            ) : new Column(
                                children: 
                                [
                                    new PanelButton(_ready ? "SET TO NOT READY" : "SET TO READY", 18.0, 1.3, null, _onReady, height:60.0, isEnabled: canBeReady),
                                    new PanelButton("START", 18.0, 1.3, const EdgeInsets.only(top:10.0), _onStart, height:60.0, isAccented: canStart, isEnabled: canStart)
                                ],
                            )

                        ]
                    )
                )
            );
    }   
}