import "package:flutter/material.dart";
import "dart:ui" as ui;
import "dart:math";
import "package:flare/flare.dart" as flr;
import "package:flare/animation/actor_animation.dart";
import "dart:typed_data";
import "package:flutter/scheduler.dart";
import "server.dart";

class ScoreDopamine extends LeafRenderObjectWidget
{
	final GameServer server;
	final Offset upperLeft;
	final Offset lowerRight;
	ScoreDopamine(
		this.server,
		this.upperLeft,
		this.lowerRight,
		{
			Key key, 
		}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new ScoreDopamineRenderObject(server, upperLeft, lowerRight);
	}

	@override
	void updateRenderObject(BuildContext context, covariant ScoreDopamineRenderObject renderObject)
	{
		renderObject..server = server
					..upperLeft = upperLeft
					..lowerRight = lowerRight;
	}
}


class ScoreParagraph
{
	ui.Paragraph paragraph;
	Size size;
	Offset center;
	double life = 0.0;
	Color color;
	String label;
	Offset velocity;

	static final RegExp reg = new RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))");
	static final Function matchFunc = (Match match) => "${match[1]},";

	static const PositiveScoreColor = const Color.fromRGBO(124, 253, 245, 1.0);
	static const NegativeScoreColor = const Color.fromRGBO(255, 76, 205, 1.0);

	ScoreParagraph(int score)
	{
		color = score < 0 ? NegativeScoreColor : PositiveScoreColor;
		label = (score > 0 ? "+" : "") + score.round().toString().replaceAllMapped(reg, matchFunc);
		setLife(0.0);
	}

	ScoreParagraph.withText(String text, bool positive)
	{
		color = positive ? PositiveScoreColor : NegativeScoreColor;
		label = text;
		setLife(0.0);
	}

	bool advance(double seconds)
	{
		center += velocity*seconds;
		return setLife(life + seconds*1.3);
	}

	bool setLife(double v)
	{
		life = v.clamp(0.0, 1.0);
		double opacity;// = (1.0-life).clamp(0.0, 1.0);
		const double fadeIn = 0.5;
		const double fadeHold = 0.2;
		const double fadeOut = 1.0-(fadeIn+fadeHold);
		if(life < fadeIn)
		{
			opacity = life/fadeIn;
		}
		else if(life < fadeHold)
		{
			opacity = 1.0;
		}
		else
		{
			opacity = (1.0-((life - fadeIn - fadeHold)/fadeOut)).clamp(0.0, 1.0);
		}
		
		ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
			textAlign:TextAlign.start,
			fontFamily: "Inconsolata",
			fontWeight: FontWeight.w700,
			fontSize: ui.lerpDouble(40.0, 120.0, Curves.easeInOut.transform(life))
		))..pushStyle(new ui.TextStyle(color:new Color.fromRGBO(color.red, color.green, color.blue, opacity)));
		builder.addText(label);
		paragraph = builder.build();
		paragraph.layout(new ui.ParagraphConstraints(width: double.infinity));
		List<ui.TextBox> boxes = paragraph.getBoxesForRange(0, label.length);
		size = new Size(boxes.last.right-boxes.first.left, boxes.last.bottom - boxes.first.top);

		return life >= 1.0;
	}
}

class ScoreDopamineRenderObject extends RenderBox
{
	GameServer _server;
	Offset _upperLeft;
	Offset _lowerRight;
	double _lastFrameTime = 0.0;

	List<ScoreParagraph> _scores = new List<ScoreParagraph>();

	ScoreDopamineRenderObject(GameServer server, Offset upperLeft, Offset lowerRight)
	{
		this.server = server;
		this.upperLeft = upperLeft;
		this.lowerRight = lowerRight;
		
		SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
	}

	void onScoreIncreased(int amount)
	{
		showScoreParagraph(new ScoreParagraph(amount));
	}

	void showScoreParagraph(ScoreParagraph paragraph)
	{
		Random rand = new Random();

		Offset center = (lowerRight - upperLeft)/2.0;
		Offset offCenter = new Offset((lowerRight.dx - upperLeft.dx)*rand.nextDouble(), (lowerRight.dy - upperLeft.dy)*rand.nextDouble());
		paragraph.center = _upperLeft + offCenter;
		paragraph.velocity = offCenter - center;
		paragraph.velocity /= paragraph.velocity.distance;
		paragraph.velocity *= 100.0;
		_scores.add(paragraph);
	}

	void onIssuingFinalValues()
	{
		showScoreParagraph(new ScoreParagraph.withText("FINAL STRETCH!!", true));
	}

	GameServer get server
	{
		return _server;
	}

	set server(GameServer d)
	{
		if(_server == d)
		{
			return;
		}
		if(_server != null)
		{
			_server.onScoreIncreased = null;
			_server.onIssuingFinalValues = null;
		}
		_server = d;
		_server.onScoreIncreased = onScoreIncreased;
		_server.onIssuingFinalValues = onIssuingFinalValues;
	}

	Offset get upperLeft
	{
		return _upperLeft;
	}

	set upperLeft(Offset d)
	{
		if(_upperLeft == d)
		{
			return;
		}
		_upperLeft = d;
	}

	Offset get lowerRight
	{
		return _lowerRight;
	}

	set lowerRight(Offset d)
	{
		if(_lowerRight == d)
		{
			return;
		}
		_lowerRight = d;
	}

	void beginFrame(Duration timeStamp) 
	{
		final double t = timeStamp.inMicroseconds / Duration.microsecondsPerMillisecond / 1000.0;
		
		if(_lastFrameTime == 0)
		{
			_lastFrameTime = t;
			SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
			// hack to circumvent not being enable to initialize lastFrameTime to a starting timeStamp (maybe it's just the date?)
			// Is the FrameCallback supposed to pass elapsed time since last frame? timeStamp seems to behave more like a date
			return;
		}
		
		double elapsed = (t - _lastFrameTime).clamp(0.0, 1.0);
		_lastFrameTime = t;

		// _testTimer += elapsed;
		// if(_testTimer > 2.0)
		// {
		// 	_testTimer = 0.0;
		// 	onScoreIncreased(new Random().nextInt(10000));
		// }
		
		List<ScoreParagraph> removeScores = new List();
		for(ScoreParagraph score in _scores)
		{
			if(score.advance(elapsed))
			{
				removeScores.add(score);
			}
		}

		for(ScoreParagraph score in removeScores)
		{
			_scores.remove(score);
		}

		SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
		markNeedsPaint();
	}

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
	
	@override
	void paint(PaintingContext context, Offset offset)
	{
		final Canvas canvas = context.canvas;
		
		if(upperLeft == null || lowerRight == null)
		{
			return;
		}
		
		
		//Size spawnArea = new Size(lowerRight.dx - upperLeft.dx, lowerRight.dy - upperLeft.dy);
		//canvas.drawRect(upperLeft & spawnArea, new Paint()..color = const Color.fromRGBO(255, 255, 0, 0.2));
		for(ScoreParagraph score in _scores)
		{
			canvas.drawParagraph(score.paragraph, new Offset(score.center.dx- score.size.width/2.0, score.center.dy - score.size.height/2.0));
		}
		
		
	}
}
