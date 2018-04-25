import "package:flutter/material.dart";
import "high_scores.dart";
import "dart:ui" show PointMode;
import "dart:math";

final RegExp reg = new RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))");
final Function mathFunc = (Match match) => "${match[1]},";

class HighScoreLine extends StatelessWidget
{
	final String name;
	final String value;
	final int idx;


	HighScoreLine(this.idx, this.name, int v) : value = v.toString().replaceAllMapped(reg, mathFunc);

	@override
	Widget build(BuildContext context)
	{
		return new Container(height:40.0, child:new Row(
			crossAxisAlignment: CrossAxisAlignment.end,
			children: <Widget>
			[
				new Container(width: 40.0, margin:const EdgeInsets.only(right:20.0), child:new Text(idx.toString(), textAlign: TextAlign.right, style: new TextStyle(color: new Color.fromRGBO(255, 255, 255, 0.3), fontFamily: "Inconsolata", fontSize: 40.0, decoration: TextDecoration.none))),
				new Text(name, style: new TextStyle(color: new Color.fromRGBO(253, 205, 242, 0.6), fontFamily: "Inconsolata", fontSize: 40.0, decoration: TextDecoration.none)),
				new Expanded
				(
					child:new Container
					(
						alignment: Alignment.bottomLeft,
						decoration: new DottedDecoration(),
						height: 1.0, 
						margin: new EdgeInsets.only(left: 10.0, right: 0.0, bottom: 4.0),
                    ),
				),
				new Text(value, textAlign: TextAlign.right, style: new TextStyle(color: new Color.fromRGBO(133, 226, 255, 0.6), fontFamily: "Inconsolata", fontSize: 40.0, decoration: TextDecoration.none))
			]
		));
	}
}

class HighScoresScreen extends StatelessWidget
{
	final HighScores _highScores;

	HighScoresScreen(this._highScores);

	@override
	Widget build(BuildContext context)
	{
		return new Container
		(
			decoration: new BoxDecoration
			(
				color: const Color.fromRGBO(255, 159, 159, 0.07),
				borderRadius: new BorderRadius.circular(5.0)
			),
			child: new Column
			(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: <Widget>
				[
					new Container
					(
						width: double.infinity,
						//height: 55.0,
						padding: const EdgeInsets.all(20.0),
						decoration: new BoxDecoration
						(
							color: const Color.fromRGBO(255, 159, 159, 0.07),
							borderRadius: new BorderRadius.only(topLeft: const Radius.circular(5.0), topRight: const Radius.circular(5.0))
						),
						child: new Text("HIGH SCORES", style: new TextStyle(letterSpacing:5.0, color: new Color.fromARGB(128, 255, 255, 255), fontFamily: "Roboto", fontSize: 19.0, decoration: TextDecoration.none))
					),
					new Expanded
					(
						child: new Container
						(
							margin: const EdgeInsets.only(top: 30.0, bottom: 30.0, left: 20.0, right: 40.0),
							child:new Column
							(
								children:<Widget>
								[
									new HighScoreLine(1, "ABC", 1343000),
									new HighScoreLine(2, "DEF", 303430),
									new HighScoreLine(3, "GHI", 1030),
									new HighScoreLine(4, "ABC", 1343000),
									new HighScoreLine(5, "DEF", 303430),
									new HighScoreLine(6, "GHI", 1030),
									new HighScoreLine(7, "ABC", 1343000),
									new HighScoreLine(8, "DEF", 303430),
									new HighScoreLine(9, "GHI", 1030),
									new HighScoreLine(10, "ABC", 1343000)
								]
							)
						)
					)
				]
			)
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
    static const int POINTS_OFFSET = 20;

    @override
    void paint(Canvas canvas, Offset offset, ImageConfiguration configuration)
    {
        double availableWidth = configuration.size.width;
        int numPoints = (availableWidth/POINTS_OFFSET).ceil();

        Paint dotsPaint = new Paint()
            ..strokeWidth = 3.0
            ..color = const Color.fromRGBO(253, 205, 242, 0.27);

        List<Offset> dots = new List(numPoints);
        for(int i = 0; i < numPoints; i++)
        {
            double dx = offset.dx + i * POINTS_OFFSET;
            dots[i] = new Offset(dx, offset.dy);
        }
        canvas.drawPoints(PointMode.points, dots, dotsPaint);
    }
}