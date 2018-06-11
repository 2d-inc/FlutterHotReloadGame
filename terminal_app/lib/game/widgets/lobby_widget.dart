import 'package:flutter/widgets.dart';

import "../blocs/connection_bloc.dart";
import "../decorations/game_colors.dart";
import "../game.dart";
import "../game_provider.dart";
import "command_panel.dart";
import "panel_button.dart";
import "players_widget.dart";

/// [Widget] that's present in the Game Lobby, while waiting for other players to join.
/// This element is composed of a list of Players with their respective status (READY|NOT READY)
/// and two [PanelButton]s: one for setting said status and the other to start the game.
class LobbyWidget extends StatelessWidget
{
    /// The opacity is passed by the [_TerminaState] so that this widget can be animated.
    final double _opacity;

    const LobbyWidget(this._opacity, { Key key  } ) : super(key: key);

    /// This column is the main compononent of the widget. It gets all the information it needs from the
    /// [GameConnectionBloc], showing how many players are present and which ones are ready.
    Widget buildColumn(BuildContext ctx, AsyncSnapshot<ConnectionInfo> snapshot, Game game)
    {
        ConnectionInfo ci = snapshot.data;
        if(ci == null)
        {
            return Container();
        }

        int readyNum = 0;
        for(var p in ci.arePlayersReady)
        {
            if(p)
            {
                readyNum++;
            }
        }

        /// Once at least two players have set to ready, and the current player is one of them,
        /// the START [PanelButton] lights up and a game can be started.
        bool canStart = ci.isReady && readyNum > 1;
        bool canBeReady = ci.isConnected && ci.canBeReady;

        return new Column(
                        mainAxisSize: MainAxisSize.max,
                        children: 
                        [
                            /// Players Row
                            new CommandPanel(new PlayerListWidget(!canBeReady, ci.arePlayersReady)),
                            /// Filler
                            new Expanded(child: new Container()),
                            /// If the local player has pressed the start button, all the players
                            /// marked as 'READY' need to do the same, so this component will remove the buttons
                            /// and show a text message instead.
                            ci.markedStart ? 
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
                            ) : 
                            /// 'READY' and 'START' buttons shown at the bottom of the Column.
                            new Column(
                                children: 
                                [
                                    /// These two [PanelButton]s are passed in callbacks so that they can react to taps.
                                    /// [SocketClient] needs to know when a player is ready, or when a game is ready to start.
                                    new PanelButton(ci.isReady ? "SET TO NOT READY" : "SET TO READY", 18.0, 1.3, null, game.client?.onReady, height:60.0, isEnabled: canBeReady),
                                    new PanelButton("START", 18.0, 1.3, const EdgeInsets.only(top:10.0), game.client?.onStart, height:60.0, isAccented: canStart, isEnabled: canStart)
                                ],
                            )
                        ]
                    );
    }

    @override
    Widget build(BuildContext context)
    {
        Game game = GameProvider.of(context);

        return new Expanded(
                child: new Opacity(
                    opacity: _opacity,
                    child: StreamBuilder(
                        stream: game.gameConnectionBloc.stream,
                        builder: (ctx, snapshot) => buildColumn(ctx, snapshot, game)
                    )
                )
            );
    }   
}