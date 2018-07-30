import "package:flutter/material.dart";

import "../decorations/dotted_row.dart";

enum PlayerStatus { READY, NOT_READY }

/// Show the list of currently active players in the lobby. 
/// This list is laid out in a [Table] widget, showing how many players are 
/// in the game and how many are ready to play.
class PlayerListWidget extends StatelessWidget 
{
    final bool isInGame;
    final List<bool> _arePlayersReady;

    PlayerListWidget(this.isInGame, this._arePlayersReady, {Key key}) : super(key: key);

    @override
    Widget build(BuildContext context)
    {
        List<TableRow> c = new List<TableRow>(_arePlayersReady.length);
        for(int i = 0; i < c.length; i++)
        {
            c[i] = (new PlayerRow("Player ${i+1}", isInGame, _arePlayersReady[i]));
        }

        return new Table(
            children: c, 
            defaultVerticalAlignment: TableCellVerticalAlignment.bottom,
            columnWidths: 
            {
                0: const MinColumnWidth(const IntrinsicColumnWidth(), const FractionColumnWidth(0.5)),
                1: const FlexColumnWidth(),
                2: const IntrinsicColumnWidth()
            },
        );
    }
}

/// Every row is made of three [Container]s, first one showing the player number, the second one uses 
/// a custom [DottedRowDecoration] to line up with the Player's state, whic is shown right-aligned in the table.
class PlayerRow extends TableRow
{
    static const Map<bool, Map> READY_MAP = const 
    {
        true: const 
        {
            "color": const Color.fromARGB(255, 86, 234, 246),
            "text": "READY",
            "weight": FontWeight.w700
        },
        false: const 
        {
            "color": const Color.fromARGB(204, 22, 75, 81),
            "text": "NOT READY",
            "weight": FontWeight.w100
        }
    };

    PlayerRow(String name, bool isInGame, bool readyStatus, { Key k, Decoration dec })
        : super(
            key: k,
            decoration: dec,
            children:
            [
                new Container(
                    child: new Text(name, style: new TextStyle(color: new Color.fromARGB(255, 45, 207, 220), fontFamily: "Inconsolata", fontWeight: FontWeight.w100, fontSize: 18.0, decoration: TextDecoration.none))),
                new Container(
                    alignment: Alignment.bottomLeft,
                    decoration: new DottedRowDecoration(),
                    height: 1.0, 
                    margin: new EdgeInsets.only(left: 10.0, right: 10.0, bottom: 4.0),
                    ),
                new Container(
                    alignment: Alignment.centerRight,
                    child:
                    new Text(
                        readyStatus && isInGame ? "IN GAME" : READY_MAP[readyStatus]["text"], // Text string
                        style: new TextStyle(color: READY_MAP[readyStatus]["color"], fontFamily: "Inconsolata", fontWeight: READY_MAP[readyStatus]["weight"], fontSize: 18.0, decoration: TextDecoration.none)
                    )
                ),
            ]
        );
}