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
    final int _readyCount;

    const LobbyWidget(this._ready, this._readyCount, this._opacity, this._onReady, this._onStart, { Key key  } ) : super(key: key);

    @override
    Widget build(BuildContext context)
    {
        return new Expanded(
                child: new Opacity(
                    opacity: _opacity,
                    child: new Column(
                        mainAxisSize: MainAxisSize.max,
                        children: 
                        [
                            // Players Row
                            new CommandPanel(new PlayerListWidget(this._ready, this._readyCount)),
                            // Filler
                            new Expanded(child: new Container()),
                            // Buttons
                            new Column(
                                children:
                                [
                                    new PanelButton(_ready ? "SET TO NOT READY":"SET TO READY", 59.0, 18.0, 1.3, null, _onReady),
                                    new PanelButton("START", 59.0, 18.0, 1.3, const EdgeInsets.only(top:10.0), _onStart, isAccented: true)
                                ],
                            )

                        ]
                    )
                )
            );
    }   
}