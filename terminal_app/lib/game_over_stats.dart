import "package:flutter/material.dart";
import "dart:ui" as ui;
import "dart:math";
import "package:flare/flare.dart" as flr;
import "package:flare/animation/actor_animation.dart";
import "dart:typed_data";
import "package:flutter/scheduler.dart";
import "package:flare/flare.dart" as flr;
import "package:flare/animation/actor_animation.dart";

class AudioPlayerDelegate
{
	void playAudio(String url);
}

class GameStats extends LeafRenderObjectWidget
{
	final double progress;
	final int score;
	final int lives;
	final int rank;
	final int totalScore;
	final int lifeScore;
	final DateTime showTime;
	final AudioPlayerDelegate player;

	GameStats(
		this.showTime,
		this.progress,
		this.score,
		this.lives,
		this.rank,
		this.totalScore,
		this.lifeScore,
		this.player,
		{
			Key key, 
		}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new GameStatsRenderObject(showTime, progress, score, lives, rank, totalScore, lifeScore, player);
	}

	@override
	void updateRenderObject(BuildContext context, covariant GameStatsRenderObject renderObject)
	{
		renderObject..showTime = showTime
					..progress = progress
					..score = score
					..lives = lives
					..rank = rank
					..totalScore = totalScore
					..player = player
					..lifeScore = lifeScore;
	}
}

class StatParagraph
{
	static const double MaxWidth = 4096.0;
	ui.Paragraph paragraph;
	Size size;
	Size finalSize;
	Size baseSize;
	Offset center;
	double life = 0.0;
	Color color;
	String label;
	String calculatedLabel;
	String fontFamily;
	int fontSize;
	double letterSpacing;
	FontWeight weight;
	Offset velocity;
	double scale = 1.0;
	double factor = 0.0;

	static const PositiveScoreColor = const Color.fromRGBO(124, 253, 245, 1.0);
	static const NegativeScoreColor = const Color.fromRGBO(255, 76, 205, 1.0);

	StatParagraph(this.label, this.fontFamily, this.fontSize, this.letterSpacing, this.weight, this.color)
	{
		layout(0.0, 1.0, 1.0);
		baseSize = size;
	}

	void layout(double f, double scale, double opacity)
	{
		this.scale = scale;
		this.factor = f;
		ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
			textAlign: TextAlign.left,
			fontFamily: fontFamily,
			fontWeight: weight,
			fontSize: fontSize*scale
		))..pushStyle(new ui.TextStyle(letterSpacing:letterSpacing, color:new Color.fromRGBO(color.red, color.green, color.blue, color.opacity*opacity)));
		builder.addText(label);
		paragraph = builder.build();
		paragraph.layout(new ui.ParagraphConstraints(width: MaxWidth));
		List<ui.TextBox> boxes = paragraph.getBoxesForRange(0, label.length);
		size = new Size(boxes.last.right-boxes.first.left, boxes.last.bottom - boxes.first.top);

		if(calculatedLabel != label)
		{
			calculatedLabel = label;
			ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
				textAlign: TextAlign.left,
				fontFamily: fontFamily,
				fontWeight: weight,
				fontSize: fontSize.toDouble()
			))..pushStyle(new ui.TextStyle(letterSpacing:letterSpacing, color:new Color.fromRGBO(color.red, color.green, color.blue, color.opacity)));
			builder.addText(label);
			ui.Paragraph paragraph = builder.build();
			paragraph.layout(new ui.ParagraphConstraints(width: MaxWidth));
			List<ui.TextBox> boxes = paragraph.getBoxesForRange(0, label.length);
			finalSize = new Size(boxes.last.right-boxes.first.left, boxes.last.bottom - boxes.first.top);
		}
	}

	double get height
	{
		return baseSize.height;
	}

	double get width
	{
		return baseSize.width;
	}

	double get finalWidth
	{
		return finalSize.width;
	}

	void draw(ui.Canvas canvas, Offset offset, Offset pivot)
	{
		//canvas.drawParagraph(paragraph, new Offset(offset.dx + baseSize.width/2.0-size.width/2.0, offset.dy + baseSize.height/2.0 - size.height/2.0));
		//double scale = size.width/baseSize.width;
		//canvas.drawParagraph(paragraph, new Offset(offset.dx + 100.0*(1.0-scale), offset.dy + baseSize.height/2.0 - size.height/2.0));
		
		Offset move = offset-pivot;
		canvas.drawParagraph(paragraph, new Offset(offset.dx + move.dx*(1.0-factor), offset.dy + move.dy*(1.0-factor)));
	}
}

class GameStatsRenderObject extends RenderBox
{
	static final RegExp reg = new RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))");
	static final Function matchFunc = (Match match) => "${match[1]},";

	flr.FlutterActor _heart;
	Float32List _heartAABB;

	double _progress;
	int _score;
	int _lives;
	int _rank;
	int _totalScore;
	int _lifeScore;

	double _lastFrameTime = 0.0;

	StatParagraph _message;
	StatParagraph _progressLabel;
	StatParagraph _scoreLabel;
	StatParagraph _livesMultiplierLabel;
	StatParagraph _finalScoreLabel;
	StatParagraph _rankLabel;

	StatParagraph _scoreValue;
	StatParagraph _livesValue;
	StatParagraph _finalScoreValue;
	StatParagraph _rankValue;
	StatParagraph _progressValue;

	DateTime _shakeTime;
	Offset _shakeOffset = Offset.zero;
	Offset _renderShakeOffset = Offset.zero;
	int _lastIndex;
	double _heartFactor = 0.0;
	double _progressFactor = 0.0;
	AudioPlayerDelegate _player;

	DateTime _showTime;

	static const Color labelColor = const Color.fromRGBO(255, 255, 255, 0.5);

	GameStatsRenderObject(DateTime showTime, double progress, int score, int lives, int rank, int totalScore, int lifeScore, AudioPlayerDelegate player)
	{
		this.showTime = showTime;
		this.progress = progress;
		this.score = score;
		this.lives = lives;
		this.rank = rank;
		this.totalScore = totalScore;
		this.lifeScore = lifeScore;
		this.player = player;
		
		_message = new StatParagraph("YOU WON!", "Roboto", 64, null, FontWeight.normal, Colors.white);
		_progressLabel = new StatParagraph("PROGRESS", "Roboto", 19, 5.0, FontWeight.normal, labelColor);
		_scoreLabel = new StatParagraph("SCORE", "Roboto", 19, 5.0, FontWeight.normal, labelColor);
		_livesMultiplierLabel = new StatParagraph("LIVES MULTIPLIER", "Roboto", 19, 5.0, FontWeight.normal, labelColor);
		_finalScoreLabel = new StatParagraph("FINAL SCORE", "Roboto", 19, 5.0, FontWeight.normal, labelColor);
		_rankLabel = new StatParagraph("RANK", "Roboto", 19, 5.0, FontWeight.normal, labelColor);
		
		_scoreValue = new StatParagraph("0", "Inconsolata", 50, null, FontWeight.normal, Colors.white);
		_livesValue = new StatParagraph("0x", "Inconsolata", 50, null, FontWeight.normal, Colors.white);
		_finalScoreValue = new StatParagraph("0", "Inconsolata", 50, null, FontWeight.normal, Colors.white);
		_rankValue = new StatParagraph("0", "Inconsolata", 50, null, FontWeight.normal, Colors.white);
		_progressValue = new StatParagraph("0", "Roboto", 19, null, FontWeight.w700, Colors.white);
		
		//SchedulerBinding.instance.scheduleFrameCallback(beginFrame);

		flr.FlutterActor actor = new flr.FlutterActor();
		actor.loadFromBundle("assets/flares/Heart").then(
			(bool success)
			{
				_heart = actor;
				if(_heart != null)
				{
					_heart.advance(0.0);
					_heartAABB = _heart.computeAABB();
					
					markNeedsLayout();
					markNeedsPaint();
				}
			}
		);
	}

	AudioPlayerDelegate get player
	{
		return _player;
	}

	set player(AudioPlayerDelegate d)
	{
		if(_player == d)
		{
			return;
		}
		_player = d;
	}

	DateTime get showTime
	{
		return _showTime;
	}

	set showTime(DateTime d)
	{
		if(_showTime == d)
		{
			return;
		}
		_showTime = d;
	}

	double get progress
	{
		return _progress;
	}

	set progress(double d)
	{
		if(_progress == d)
		{
			return;
		}
		_progress = d;
	}

	int get lives
	{
		return _lives;
	}

	set lives(int d)
	{
		if(_lives == d)
		{
			return;
		}
		_lives = d;
	}

	int get score
	{
		return _score;
	}

	set score(int d)
	{
		if(_score == d)
		{
			return;
		}
		_score = d;
	}

	int get rank
	{
		return _rank;
	}

	set rank(int d)
	{
		if(_rank == d)
		{
			return;
		}
		_rank = d;
	}

	int get totalScore
	{
		return _totalScore;
	}

	set totalScore(int d)
	{
		if(_totalScore == d)
		{
			return;
		}
		_totalScore = d;
	}

	int get lifeScore
	{
		return _lifeScore;
	}

	set lifeScore(int d)
	{
		if(_lifeScore == d)
		{
			return;
		}
		_lifeScore = d;
	}

	// void beginFrame(Duration timeStamp) 
	// {
	// 	final double t = timeStamp.inMicroseconds / Duration.microsecondsPerMillisecond / 1000.0;
		
	// 	if(_lastFrameTime == 0)
	// 	{
	// 		_lastFrameTime = t;
	// 		SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
	// 		return;
	// 	}
		
	// 	double elapsed = (t - _lastFrameTime).clamp(0.0, 1.0);
	// 	_lastFrameTime = t;

	// 	SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
	// 	markNeedsPaint();
	// }

	@override
	bool get sizedByParent => true;
	
	@override
	bool hitTestSelf(Offset screenOffset) => false;

	@override
	void performResize() 
	{
		size = new Size(constraints.constrainWidth(), constraints.constrainHeight());
	}

	@override
	void performLayout()
	{
		super.performLayout();
	}
	
	static const double secondsPerSection = 0.2;
	static const double secondsPaddingPerSection = 0.22;
	static const double shakeAhead = 0.05;
	
	int index(double seconds)
	{
		seconds += secondsPaddingPerSection + shakeAhead;
		return max(0,(seconds/(secondsPerSection+secondsPaddingPerSection)).floor());
	}

	double sectionF(int idx, double seconds)
	{
		return Curves.easeInOut.transform(linSectionF(idx, seconds));
	}

	double linSectionF(int idx, double seconds)
	{
		return ((seconds-idx*(secondsPerSection+secondsPaddingPerSection))/secondsPerSection).clamp(0.0, 1.0);
	}

	double getScale(double f)
	{
		return ui.lerpDouble(2.0, 1.0, f);
	}

	double getOpacity(double f)
	{
		return ui.lerpDouble(0.0, 1.0, f);
	}
	Random rand = new Random();
	void advanceAnimation()
	{
		//const int duration = 7000;
		//double seconds = new DateTime.now().millisecondsSinceEpoch%duration/1000.0;
		//double seconds = max(0.0, ((new DateTime.now().millisecondsSinceEpoch - _showTime.millisecondsSinceEpoch)%7000)/1000.0);
		double seconds = max(0.0, ((new DateTime.now().millisecondsSinceEpoch - _showTime.millisecondsSinceEpoch))/1000.0);

		int ix = index(seconds);
		if(ix != _lastIndex && ix >= 0 && ix <= 11)
		{
			_lastIndex = ix;
			if(ix > 0)
			{
				_shakeTime = new DateTime.now();
				if(player != null)
				{
					player.playAudio("assets/audio/hit${rand.nextInt(2)+1}.wav");
				}
			}

			switch(ix)
			{
				case 0:
					player.playAudio(_lives == 0 ? "assets/audio/game_over_lose.wav" : "assets/audio/game_over_win.wav");
					break;
				case 4:
				case 8:
					//player.playAudio("assets/audio/point_counting.wav");
					break;
			}
		}

		if(_shakeTime != null)
		{
			double shakeAmount = 1.0-((new DateTime.now().millisecondsSinceEpoch - _shakeTime.millisecondsSinceEpoch)/220.0).clamp(0.0, 1.0);
			if(shakeAmount > 0.0)
			{
				const double shakeIntensity = 25.0;
				Offset targetShakeOffset = new Offset((rand.nextDouble()-0.5)*2.0 * shakeIntensity, (rand.nextDouble()-0.5)*2.0 * shakeIntensity);
				_shakeOffset += (targetShakeOffset-_shakeOffset)*0.7;
				_renderShakeOffset = _shakeOffset * shakeAmount;
			}
			else
			{
				_renderShakeOffset = Offset.zero;
			}
		}
		double f = sectionF(0, seconds);

		_message.label = _lives > 0 ? "YOU WON!" : "YOU LOST!";
		_message.layout(f, getScale(f), getOpacity(f));

		f = sectionF(1, seconds);
		_progressLabel.layout(f, getScale(f), getOpacity(f));
		_progressFactor = sectionF(2, seconds);
		_progressValue.label = (_progress*linSectionF(1, seconds)*100.0).round().toString() + "%";
		_progressValue.layout(f, getScale(f), getOpacity(f));

		f = sectionF(3, seconds);
		_scoreLabel.layout(f, getScale(f), getOpacity(f));

		f = sectionF(4, seconds);
		_scoreValue.label = (_score*linSectionF(4, seconds)).round().toString().replaceAllMapped(reg, matchFunc);
		_scoreValue.layout(f, getScale(f), getOpacity(f));

		f = sectionF(5, seconds);
		_livesMultiplierLabel.layout(f, getScale(f), getOpacity(f));

		f = sectionF(6, seconds);
		_livesValue.label = "${_lives}x $_lifeScore";
		_heartFactor = f;
		if(_heart != null)
		{
			_heart.root.opacity = getOpacity(f);
			_heart.advance(0.0);
		}
		_livesValue.layout(f, getScale(f), getOpacity(f));

		f = sectionF(7, seconds);
		_finalScoreLabel.layout(f, getScale(f), getOpacity(f));

		f = sectionF(8, seconds);
		_finalScoreValue.label = (_totalScore*linSectionF(8, seconds)).round().toString().replaceAllMapped(reg, matchFunc);
		_finalScoreValue.layout(f, getScale(f), getOpacity(f));

		f = sectionF(9, seconds);
		_rankLabel.layout(f, getScale(f), getOpacity(f));

		f = sectionF(10, seconds);
		_rankValue.label = _rank.toString();
		_rankValue.layout(f, getScale(f), getOpacity(f));
	}
	@override
	void paint(PaintingContext context, Offset offset)
	{
		final Canvas canvas = context.canvas;

		const int padding = 10;

		advanceAnimation();

		canvas.save();
		if(_renderShakeOffset != null)
		{
			canvas.translate(_renderShakeOffset.dx, _renderShakeOffset.dy);
		}

		Offset center = offset + new Offset(size.width/2.0, size.height/2.0);

		Offset currentOffset = offset;
		_message.draw(canvas, currentOffset, center);

		currentOffset += new Offset(0.0, _message.height + padding);
		_progressLabel.draw(canvas, currentOffset, center);

		{
			_progressValue.draw(canvas, currentOffset + new Offset(size.width-_progressValue.finalWidth, 0.0), center);
			currentOffset += new Offset(0.0, _progressLabel.height);

			double progressOpacity = getOpacity(_progressFactor);
			double progressScale = getScale(_progressFactor);
			const int progressNumTicks = 8;
			final double progressWidth = size.width*progressScale;
			final double progressHeight = 12.1*progressScale;


			Offset progressOff = new Offset(currentOffset.dx, currentOffset.dy + 50.0/2.0 - progressHeight/2.0);
			
			Offset move = progressOff-center;
			progressOff = new Offset(progressOff.dx + move.dx*(1.0-_progressFactor), progressOff.dy + move.dy*(1.0-_progressFactor));
			
			Size barSize = new Size(progressWidth, progressHeight);    

			
			canvas.drawRRect(new RRect.fromRectAndRadius(progressOff&barSize, const Radius.circular(6.0)), new Paint()..color = new Color.fromRGBO(255, 255, 255,	progressOpacity));
			Size fillSize = new Size(progressWidth*_progress*_progressFactor, progressHeight);
			canvas.drawRRect(new RRect.fromRectAndRadius(progressOff&fillSize, const Radius.circular(6.0)), new Paint()..color = new Color.fromRGBO(13, 129, 181, progressOpacity));

			double tickDistance = (progressWidth - 13)/(progressNumTicks);
			double xOffset = progressOff.dx + 5.0;
			double numHighlightedTicks = progressNumTicks * _progress * _progressFactor;
			for(int i = 0; i < progressNumTicks+1; i++)
			{
				Offset tickOffset = new Offset(xOffset + i * tickDistance, progressOff.dy + progressHeight);
				const Size tick = const Size(3.0, 5.0);
				bool isHighlighted = _progress > 0 && i <= numHighlightedTicks;
				canvas.drawRect(tickOffset&tick, new Paint()..color = isHighlighted ? new Color.fromRGBO(13, 129, 181, progressOpacity) : Color.fromRGBO(255,255,255, progressOpacity*0.2));
			}
			

		}

		currentOffset += new Offset(0.0, 50.0);
		_scoreLabel.draw(canvas, currentOffset, center);

		currentOffset += new Offset(0.0, _scoreLabel.height);
		_scoreValue.draw(canvas, currentOffset, center);

		currentOffset += new Offset(0.0, _scoreValue.height + padding);
		_livesMultiplierLabel.draw(canvas, currentOffset, center);
		currentOffset += new Offset(0.0, _livesMultiplierLabel.height);
		_livesValue.draw(canvas, currentOffset, center);
		
		if(_heartAABB != null)
		{
			const double heartPadding = 9.0;
			final double heartWidth = _heartAABB[2] - _heartAABB[0];
			final double heartHeight = _heartAABB[3] - _heartAABB[1];
			for(int i = 0; i < _lives; i++)
			{
				canvas.save();
				Offset heartOff = new Offset(currentOffset.dx + size.width - heartWidth - i*(heartWidth+heartPadding), currentOffset.dy + _livesValue.height/2.0 - heartHeight/2.0);
				
				Offset move = heartOff-center;
				heartOff = new Offset(heartOff.dx + move.dx*(1.0-_heartFactor), heartOff.dy + move.dy*(1.0-_heartFactor));
				canvas.translate(heartOff.dx, heartOff.dy);
				_heart.draw(canvas);
				canvas.restore();		
			}
		}
		

		currentOffset += new Offset(0.0, _livesValue.height + padding);
		_finalScoreLabel.draw(canvas, currentOffset, center);
		_finalScoreValue.draw(canvas, currentOffset + new Offset(0.0, _finalScoreLabel.height), center);
		_rankLabel.draw(canvas, currentOffset + new Offset(size.width - _rankLabel.width, 0.0), center);
		_rankValue.draw(canvas, currentOffset + new Offset(size.width - _rankValue.finalWidth, _rankLabel.height), center);

		canvas.restore();
	}
}
