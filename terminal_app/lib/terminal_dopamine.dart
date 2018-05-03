import "package:flutter/material.dart";
import "dart:ui" as ui;
import "dart:math";
import "package:flare/flare.dart" as flr;
import "package:flare/animation/actor_animation.dart";
import "dart:typed_data";
import "package:flutter/scheduler.dart";

typedef void DopamineCallback(int score);

class DopamineDelegate
{
	DopamineCallback onScored;
}

class TerminalDopamine extends LeafRenderObjectWidget
{
	final DopamineDelegate delegate;
	final Offset touchPosition;

	TerminalDopamine(
		this.delegate,
		{
			Key key, 
			this.touchPosition
		}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new TerminalDopamineRenderObject(delegate, touchPosition);
	}

	@override
	void updateRenderObject(BuildContext context, covariant TerminalDopamineRenderObject renderObject)
	{
		renderObject..delegate = delegate
					..touchPosition = touchPosition;
	}
}


class ScoreParagraph
{
	static const double MaxWidth = 4096.0;
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
		color = score > 0 ? PositiveScoreColor : NegativeScoreColor;
		label = (score > 0 ? "+" : "") + score.round().toString().replaceAllMapped(reg, matchFunc);
		if(score > 0)
		{
			label = "GREAT JOB!\n" + label;
		}
		else
		{
			label = "PAY ATTENTION!!\n" + label;
		}
		setLife(0.0);
	}

	ScoreParagraph.withText(String text, bool isPositive)
	{
		color = isPositive ? PositiveScoreColor : NegativeScoreColor;
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
			textAlign: TextAlign.center,
			fontFamily: "Inconsolata",
			fontWeight: FontWeight.w700,
			fontSize: ui.lerpDouble(40.0, 120.0, Curves.easeInOut.transform(life))
		))..pushStyle(new ui.TextStyle(color:new Color.fromRGBO(color.red, color.green, color.blue, opacity)));
		builder.addText(label);
		paragraph = builder.build();
		paragraph.layout(new ui.ParagraphConstraints(width: MaxWidth));
		List<ui.TextBox> boxes = paragraph.getBoxesForRange(0, label.length);
		size = new Size(boxes.last.right-boxes.first.left, boxes.last.bottom - boxes.first.top);

		return life >= 1.0;
	}
}

class TerminalDopamineRenderObject extends RenderBox
{
	DopamineDelegate _delegate;
	Offset _touchPosition;
	double _lastFrameTime = 0.0;

	double _testTimer = 0.0;

	List<ScoreParagraph> _scores = new List<ScoreParagraph>();

	TerminalDopamineRenderObject(DopamineDelegate delegate, Offset touchPosition)
	{
		this.delegate = delegate;
		this.touchPosition = touchPosition;

		SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
	}

	void onScoreIncreased(int amount)
	{
		showScoreParagraph(new ScoreParagraph(amount));
	}

	void showScoreParagraph(ScoreParagraph paragraph)
	{
		if(_touchPosition == null)
		{
			return;
		}
		paragraph.center = _touchPosition;
		paragraph.velocity = new Offset(0.0, -100.0);
		_scores.add(paragraph);
	}

	void onIssuingFinalValues()
	{
		showScoreParagraph(new ScoreParagraph.withText("FINAL STRETCH!!", true));
	}

	DopamineDelegate get delegate
	{
		return _delegate;
	}

	set delegate(DopamineDelegate d)
	{
		if(_delegate == d)
		{
			return;
		}
		if(_delegate != null)
		{
			_delegate.onScored = null;
		}
		_delegate = d;
		_delegate.onScored = onScoreIncreased;
	}

	Offset get touchPosition
	{
		return _touchPosition;
	}

	set touchPosition(Offset d)
	{
		if(_touchPosition == d)
		{
			return;
		}
		_touchPosition = d;
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
				
		for(ScoreParagraph score in _scores)
		{
			canvas.drawParagraph(score.paragraph, new Offset(score.center.dx-ScoreParagraph.MaxWidth/2.0, score.center.dy - score.size.height/2.0));
		}
		
		
	}
}
