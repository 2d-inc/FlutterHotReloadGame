import 'package:flutter/widgets.dart';


class CommandPanel extends StatelessWidget
{
    final Widget _child;
    final EdgeInsetsGeometry margin;
    final bool isExpanded;

    CommandPanel(this._child, { Key key, this.margin, this.isExpanded = false}) : super(key: key);
    

    Widget optionalExpansion(bool expand, Widget widget)
    {
        return expand ? new Expanded(child:widget) : widget;
    }

    @override
    Widget build(BuildContext context)
    {
        return new Column(
                    children: 
                    [
                        optionalExpansion(isExpanded, new Container(
                            margin: this.margin,
                            decoration: new BoxDecoration(border: new Border.all(width: 2.0 , color: const Color.fromARGB(255, 62, 196, 206)), borderRadius: new BorderRadius.circular(3.0), color: const Color.fromARGB(255, 3, 28, 32)),
                            padding: new EdgeInsets.symmetric(vertical: 14.0, horizontal: 18.0),
                            child: _child
                        )),
                        new Container(
                        margin: new EdgeInsets.only(top: 5.0),
                        child: new Row(
                                children:
                                [
                                    new Text("COMMAND", style: new TextStyle(color: new Color.fromARGB(255, 167, 230, 237), fontFamily: "Inconsolata", fontWeight: FontWeight.bold, fontSize: 6.0, decoration: TextDecoration.none, letterSpacing: 0.4)),
                                    new Text(" PANEL", style: new TextStyle(color: new Color.fromARGB(255, 86, 234, 246), fontFamily: "Inconsolata", fontWeight: FontWeight.bold, fontSize: 6.0, decoration: TextDecoration.none, letterSpacing: 0.5))
                                ]
                            )
                        )
                    ]
                );
    }

}