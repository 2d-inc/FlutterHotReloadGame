import 'package:flutter/widgets.dart';

import "command_panel.dart";
import "../decorations/game_colors.dart";

/// During a game, a [CommandPanel] is used as a wrapper for InGame command so that it has a title describing its type.
class TitledCommandPanel extends StatelessWidget
{
    final Widget _child;
    final String title;
    final EdgeInsetsGeometry margin;
    final bool isExpanded;

    TitledCommandPanel(this.title, this._child, { Key key, this.margin, this.isExpanded = false}) : super(key: key);

    Widget optionalExpansion(bool expand, Widget widget)
    {
        return expand ? new Expanded(child:widget) : widget;
    }

    @override
    Widget build(BuildContext context)
    {
        return new CommandPanel(
                new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:<Widget>[
                        new Container(height:1.0, decoration: new BoxDecoration(color:GameColors.lowValueContent), margin:new EdgeInsets.only(bottom:8.0)),
                        new Text("/" + title.toUpperCase(), style: new TextStyle(color: GameColors.white, fontFamily: "Inconsolata", fontWeight: FontWeight.w700, fontSize: 16.0, decoration: TextDecoration.none, letterSpacing: 1.1)),
                        new Container(height:1.0, decoration: new BoxDecoration(color:GameColors.lowValueContent), margin:new EdgeInsets.only(top:8.0, bottom: 10.0)),
                        optionalExpansion(isExpanded, _child),
                    ]
                ),
                margin:margin,
                isExpanded: isExpanded,
            );
    }

}