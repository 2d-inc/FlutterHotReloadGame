import "package:flutter/material.dart";
import "high_scores.dart";
import "dart:ui" show PointMode;
import "dart:math";
import "flare_widget.dart";

final RegExp reg = new RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))");
final Function matchFunc = (Match match) => "${match[1]},";

class HighScoreLine extends StatelessWidget
{
	final String name;
	final String value;
	final int idx;
    final int teamSize;
	final bool isHighlit;


	HighScoreLine(this.idx, this.name, int v, this.teamSize, this.isHighlit) : value = v.toString().replaceAllMapped(reg, matchFunc);

	@override
	Widget build(BuildContext context)
	{
		return new Container(
			height: 40.0, 
			decoration: isHighlit ? new HighLightDecoration() : null,
			child: new Row
			(
				//margin: const EdgeInsets.only(top: 30.0, bottom: 30.0, left: 20.0, right: 40.0),
				crossAxisAlignment: CrossAxisAlignment.end,
				children: <Widget>
				[
					new Container(width: 40.0, margin:const EdgeInsets.only(left: 20.0, right:20.0), child:new Text(idx.toString(), textAlign: TextAlign.right, style: new TextStyle(color: isHighlit ? Colors.white : new Color.fromRGBO(255, 255, 255, 0.3), fontFamily: "Inconsolata", fontSize: 40.0, decoration: TextDecoration.none))),
					new Text(name, style: new TextStyle(color: isHighlit ? Colors.white : new Color.fromRGBO(253, 205, 242, 0.6), fontFamily: "Inconsolata", fontSize: 40.0, decoration: TextDecoration.none)),
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
					new Container(margin:const EdgeInsets.only(right:20.0), child:new Text(value, textAlign: TextAlign.right, style: new TextStyle(color: isHighlit ? Colors.white : new Color.fromRGBO(133, 226, 255, 0.6), fontFamily: "Inconsolata", fontSize: 40.0, decoration: TextDecoration.none))),
                    new Container(margin:const EdgeInsets.only(right:5.0, bottom: 6.0), child:new Flare("assets/flares/players_icon", false)),
                    new Container(margin:const EdgeInsets.only(right:40.0), child:new Text(teamSize.toString(), textAlign: TextAlign.right, style: new TextStyle(color: isHighlit ? Colors.white : new Color.fromRGBO(253, 205, 242, 0.6), fontFamily: "Inconsolata", fontSize: 40.0, decoration: TextDecoration.none)))
				]
			)
		);
	}
}

class HighScoresScreen extends StatelessWidget
{
	final List<HighScore> _highScores;
	final HighScore _highScore;

	HighScoresScreen(this._highScores, this._highScore);

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
							margin: const EdgeInsets.only(top: 30.0, bottom: 30.0),
							child:new Column
							(
								children:_highScores == null ? [] : _highScores.map((HighScore score)
									{
										return new HighScoreLine(score.idx+1, score.name, score.value, score.teamSize, score == _highScore);	
									}).toList()
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

class HighLightDecoration extends Decoration
{
    @override
    BoxPainter createBoxPainter([VoidCallback onChanged])
    {
        return new HighLightDecorationPainter();
    }
}

class HighLightDecorationPainter extends BoxPainter
{
	static const Color color = const Color.fromRGBO(255, 0, 108, 0.22);

    @override
    void paint(Canvas canvas, Offset offset, ImageConfiguration configuration)
    {
        canvas.drawRect(offset & new Size(configuration.size.width, configuration.size.height + 3.0), new Paint()..color = color);
    }
}