import "package:flutter/material.dart";
import "high_scores.dart";
import "dart:ui" show PointMode;
import "dart:math";
import "game_over_stats.dart";

class GameOverScreen extends StatelessWidget
{
	final double progress;
	final int score;
	final int lives;
	final int rank;
	final int totalScore;
	final int lifeScore;
	final DateTime showTime;

	GameOverScreen(
		this.showTime,
		this.progress,
		this.score,
		this.lives,
		this.rank,
		this.totalScore,
		this.lifeScore,
		{
			Key key, 
		}): super(key: key);

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
						child: new Text("GAME OVER", style: new TextStyle(letterSpacing:5.0, color: new Color.fromARGB(128, 255, 255, 255), fontFamily: "Roboto", fontSize: 19.0, decoration: TextDecoration.none))
					),
					new Expanded
					(
						child: new Container
						(
							margin: const EdgeInsets.only(top: 30.0, left:20.0, right:200.0, bottom: 30.0),
							child: new GameStats(showTime, progress, score, lives, rank, totalScore, lifeScore)
						)
					)
				]
			)
		);
	}
}