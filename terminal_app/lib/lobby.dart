import 'package:flutter/widgets.dart';
import "command_panel.dart";
import "players_widget.dart";
import "panel_button.dart";

class LobbyWidget extends StatelessWidget
{
    final VoidCallback _onReady;
    final VoidCallback _onStart;
    final double _opacity;
    final bool _ready;
    final List<bool> _arePlayersReady;
    final bool canBeReady;

    const LobbyWidget(this.canBeReady, this._ready, this._arePlayersReady, this._opacity, this._onReady, this._onStart, { Key key  } ) : super(key: key);

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
                            new CommandPanel(new PlayerListWidget(this._arePlayersReady)),
                            // Filler
                            new Expanded(child: new Container()),
                            // Buttons
                            new Column(
                                children: 
                                [
                                    new PanelButton(_ready ? "SET TO NOT READY" : "SET TO READY", 18.0, 1.3, null, _onReady, isEnabled: canBeReady),
                                    new PanelButton("START", 18.0, 1.3, const EdgeInsets.only(top:10.0), _onStart, isAccented: canStart, isEnabled: canStart && canBeReady)
                                ],
                            )

                        ]
                    )
                )
            );
    }   
}