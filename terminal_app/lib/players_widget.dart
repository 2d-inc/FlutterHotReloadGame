import "package:flutter/material.dart";

const Color START_BUTTON_FADED = const Color.fromARGB(204, 9, 45, 51);
const Color START_BUTTON_LIT = const Color.fromARGB(255, 86, 234, 246);

enum PlayerStatus { READY, NOT_READY }

class PlayersWidget extends StatefulWidget 
{
	@override
	PlayerState createState() => new PlayerState();
}

class PlayerState extends State<PlayersWidget> 
{

    final List<PlayerStatus> _players = new List.filled(4, PlayerStatus.NOT_READY);

    @override
    Widget build(BuildContext context)
    {
        return new Column(
                            children: 
                            [
                                new Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children:
                                    [ 
                                        new Text("Player 1", style: new TextStyle(color: new Color.fromARGB(255, 45, 207, 220), fontFamily: "Inconsolata", fontWeight: FontWeight.w100, fontSize: 18.0, decoration: TextDecoration.none)),
                                        new Expanded(child: new Container(color: new Color.fromARGB(255, 43, 196, 209), height: 1.0, margin: new EdgeInsets.only(left: 10.0, right: 10.0, bottom: 4.0))),
                                        new Text("READY", style: new TextStyle(color: new Color.fromARGB(255, 86, 234, 236), fontFamily: "Inconsolata", fontWeight: FontWeight.w700, fontSize: 18.0, decoration: TextDecoration.none)),
                                    ]
                                ),
                                new Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children:
                                    [ 
                                        new Text("Player 2", style: new TextStyle(color: new Color.fromARGB(255, 45, 207, 220), fontFamily: "Inconsolata", fontWeight: FontWeight.w100, fontSize: 18.0, decoration: TextDecoration.none)),
                                        new Expanded(child: new Container(color: new Color.fromARGB(255, 43, 196, 209), height: 1.0, margin: new EdgeInsets.only(left: 10.0, right: 10.0, bottom: 4.0))),
                                        new Text("READY", style: new TextStyle(color: new Color.fromARGB(255, 86, 234, 236), fontFamily: "Inconsolata", fontWeight: FontWeight.w700, fontSize: 18.0, decoration: TextDecoration.none)),
                                    ]
                                ),
                                new Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children:
                                    [ 
                                        new Text("Player 3", style: new TextStyle(color: new Color.fromARGB(255, 45, 207, 220), fontFamily: "Inconsolata", fontWeight: FontWeight.w100, fontSize: 18.0, decoration: TextDecoration.none)),
                                        new Expanded(child: new Container(color: new Color.fromARGB(255, 43, 196, 209), height: 1.0, margin: new EdgeInsets.only(left: 10.0, right: 10.0, bottom: 4.0))),
                                        new Text("NOT READY", style: new TextStyle(color: new Color.fromARGB(255, 22, 75, 81), fontFamily: "Inconsolata", fontWeight: FontWeight.w100, fontSize: 18.0, decoration: TextDecoration.none)),
                                    ]
                                ),
                                new Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children:
                                    [ 
                                        new Text("Player 4", style: new TextStyle(color: new Color.fromARGB(255, 45, 207, 220), fontFamily: "Inconsolata", fontWeight: FontWeight.w100, fontSize: 18.0, decoration: TextDecoration.none)),
                                        new Expanded(child: new Container(color: new Color.fromARGB(255, 43, 196, 209), height: 1.0, margin: new EdgeInsets.only(left: 10.0, right: 10.0, bottom: 4.0))),
                                        new Text("NOT READY", style: new TextStyle(color: new Color.fromARGB(255, 22, 75, 81), fontFamily: "Inconsolata", fontWeight: FontWeight.w100, fontSize: 18.0, decoration: TextDecoration.none)),
                                    ]
                                ),
                            ],
                        );
    }
}