import 'dart:math';
import 'dart:ui' show PointMode;

import "package:flutter/material.dart";

enum PlayerStatus { READY, NOT_READY }

class PlayerListWidget extends StatefulWidget 
{
    final List<bool> _arePlayersReady;

    PlayerListWidget(this._arePlayersReady, {Key key}) : super(key: key);

	@override
	PlayerListState createState() => new PlayerListState();
}

class PlayerListState extends State<PlayerListWidget> 
{
    @override
    Widget build(BuildContext context)
    {
        List<TableRow> c = new List<TableRow>(widget._arePlayersReady.length);
        for(int i = 0; i < c.length; i++)
        {
            c[i] = (new PlayerRow("Player ${i+1}", widget._arePlayersReady[i]));
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

class DottedDecoration extends Decoration
{
    @override
    BoxPainter createBoxPainter([VoidCallback onChanged])
    {
        return new DottedPainter();
    }
}

class DottedPainter extends BoxPainter
{
    static const int MAX_NUM_POINTS = 10;
    static const int POINTS_OFFSET = 7;

    @override
    void paint(Canvas canvas, Offset offset, ImageConfiguration configuration)
    {
        double availableWidth = min(configuration.size.width, (MAX_NUM_POINTS * POINTS_OFFSET).toDouble());
        int numPoints = (availableWidth/POINTS_OFFSET).floor();

        Paint dotsPaint = new Paint()
            ..strokeWidth = 1.0
            ..color = Colors.cyan;

        List<Offset> dots = new List(numPoints);
        for(int i = 0; i < numPoints; i++)
        {
            double dx = offset.dx + i * POINTS_OFFSET;
            dots[i] = new Offset(dx, offset.dy);
        }
        canvas.drawPoints(PointMode.points, dots, dotsPaint);
    }
}

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

    PlayerRow(String name, bool readyStatus, { Key k, Decoration dec })
        : super(
            key: k,
            decoration: dec,
            children:
            [
                new Container(child: new Text(name, style: new TextStyle(color: new Color.fromARGB(255, 45, 207, 220), fontFamily: "Inconsolata", fontWeight: FontWeight.w100, fontSize: 18.0, decoration: TextDecoration.none))),
                new Container(
                    alignment: Alignment.bottomLeft,
                    decoration: new DottedDecoration(),
                    height: 1.0, 
                    margin: new EdgeInsets.only(left: 10.0, right: 10.0, bottom: 4.0),
                    ),
                new Container(
                    alignment: Alignment.centerRight,
                    child:
                    new Text(
                        READY_MAP[readyStatus]["text"], // Text string
                        style: new TextStyle(color: READY_MAP[readyStatus]["color"], fontFamily: "Inconsolata", fontWeight: READY_MAP[readyStatus]["weight"], fontSize: 18.0, decoration: TextDecoration.none)
                    )
                ),
            ]
        );
}