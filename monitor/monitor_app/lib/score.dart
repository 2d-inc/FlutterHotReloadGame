import "package:flutter/material.dart";

import "shadow_text.dart";

final RegExp reg = new RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))");
final Function matchFunc = (Match match) => "${match[1]},";

class GameScore extends StatefulWidget
{	
	final int score;
	GameScore(this.score);

	@override
	_GameScoreState createState() => new _GameScoreState();
}

class _GameScoreState extends State<GameScore> with SingleTickerProviderStateMixin
{
	AnimationController _controller;
	Animation<double> _scoreAnimation;
	double _score = 0.0;
	double _targetScore = 0.0;
	String _displayScore = "0";

	@override
	initState() 
	{
    	super.initState();

    	_controller = new AnimationController(duration: const Duration(milliseconds:200), vsync: this);
		_controller.addListener(()
		{
			setState(()
			{
				_score = _scoreAnimation.value;
				_displayScore = _score.round().toString().replaceAllMapped(reg, matchFunc);
			});
		});

		_changeScore(widget.score);
	}

	_changeScore(int score)
	{
		if(_targetScore == score)
		{
			return;
		}
		_targetScore = score.toDouble();
		_scoreAnimation = new Tween<double>
		(
			begin: _score,
			end: _targetScore
		).animate(_controller);

		_controller
			..value = 0.0
			..animateTo(1.0, curve:Curves.easeInOut);
	}
	
	@override
	void didUpdateWidget(GameScore oldWidget) 
	{
		_changeScore(widget.score);

		super.didUpdateWidget(oldWidget);
	}
	@override
	void dispose()
	{
		_controller.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) 
	{
		return new Container(margin:const EdgeInsets.only(bottom:7.0), child:ShadowText(_displayScore.toString(), fontFamily: "Inconsolata", fontSize: 50.0));
	}
}