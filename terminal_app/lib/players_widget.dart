import "package:flutter/material.dart";

enum PlayerStatus { READY, NOT_READY }

class PlayerListWidget extends StatefulWidget 
{
	@override
	PlayerListState createState() => new PlayerListState();
}

class PlayerListState extends State<PlayerListWidget> 
{
    final List<PlayerStatus> _players = new List.filled(4, PlayerStatus.NOT_READY);

    @override
    Widget build(BuildContext context)
    {
        List<Widget> c = new List<Widget>(_players.length);

        for(int i = 0; i < _players.length; i++)
        {
            PlayerStatus st = i % 2 == 0 ? PlayerStatus.NOT_READY : PlayerStatus.READY;
            c[i] = (new PlayerWidget("Player $i", st));
        }

        return new Column(children: c);
    }
}

class PlayerWidget extends StatefulWidget
{
    String _name;
    PlayerStatus _status;

    PlayerWidget(this._name, this._status, { Key key }) : super(key: key);

    @override
    PlayerState createState() => new PlayerState(_name, _status);
}

class PlayerState extends State<PlayerWidget>
{
    static const Map<PlayerStatus, Map> READY_MAP = const 
    {
        PlayerStatus.READY: const 
        {
            "color": const Color.fromARGB(255, 86, 234, 246),
            "text": "READY",
            "weight": FontWeight.w700
        },
        PlayerStatus.NOT_READY: const 
        {
            "color": const Color.fromARGB(204, 22, 75, 81),
            "text": "NOT READY",
            "weight": FontWeight.w100
        }
    };

    String _name;
    PlayerStatus _status;

    PlayerState(this._name, this._status) : super();

    @override
    Widget build(BuildContext context)
    {
        Map current = READY_MAP[_status];
        String readyText = current["text"];
        Color textColor = current["color"];
        FontWeight weight = current["weight"];

        return new Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children:
                        [ 
                            new Text(_name, style: new TextStyle(color: new Color.fromARGB(255, 45, 207, 220), fontFamily: "Inconsolata", fontWeight: FontWeight.w100, fontSize: 18.0, decoration: TextDecoration.none)),
                            new Expanded(child: new Container(color: new Color.fromARGB(255, 43, 196, 209), height: 1.0, margin: new EdgeInsets.only(left: 10.0, right: 10.0, bottom: 4.0))),
                            new Text(readyText, style: new TextStyle(color: textColor, fontFamily: "Inconsolata", fontWeight: weight, fontSize: 18.0, decoration: TextDecoration.none)),
                        ]
                    );
    }

}