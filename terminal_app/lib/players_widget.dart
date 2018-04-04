import 'dart:math';
import 'dart:ui' show PointMode;

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
        List<TableRow> c = new List<TableRow>(_players.length);

        for(int i = 0; i < _players.length; i++)
        {
            // TODO: remove
            PlayerStatus st = i % 2 == 0 ? PlayerStatus.NOT_READY : PlayerStatus.READY;
            c[i] = (new PlayerRow("Player ${i+1}", st));
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

    PlayerRow(String name, PlayerStatus status, { Key k, Decoration dec })
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
                        READY_MAP[status]["text"], // Text string
                        style: new TextStyle(color: READY_MAP[status]["color"], fontFamily: "Inconsolata", fontWeight: READY_MAP[status]["weight"], fontSize: 18.0, decoration: TextDecoration.none)
                    )
                ),
            ]
        );
}