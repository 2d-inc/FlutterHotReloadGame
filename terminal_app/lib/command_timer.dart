import 'package:flutter/material.dart';
import "dart:ui" as ui;

class CommandTimer extends LeafRenderObjectWidget
{
	final DateTime startTime;
	final DateTime endTime;
	final double opacity;

	CommandTimer({Key key, this.startTime, this.endTime, this.opacity}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new CommandTimerRenderer(startTime, endTime, opacity);
	}

	@override
	void updateRenderObject(BuildContext context, covariant CommandTimerRenderer renderObject)
	{
		renderObject..startTime = startTime
					..endTime = endTime
					..opacity = opacity;
	}
}

String formatDuration(Duration d) 
{
    String twoDigits(int n) 
	{
      if (n >= 10) return "$n";
      return "0$n";
    }

	if(d.inMilliseconds < 0)
	{
		return "00:00";
	}

    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(Duration.minutesPerHour));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(Duration.secondsPerMinute));
    return "$twoDigitMinutes:$twoDigitSeconds";
}

class CommandTimerRenderer extends RenderBox
{
	DateTime _startTime;
	DateTime _endTime;
	double _opacity;

	static const Color angryTime = const Color.fromARGB(255, 255, 72, 0);
	static const Color urgentTime = const Color.fromARGB(255, 255, 191, 0);
	static const Color relaxedTime = const Color.fromARGB(255, 86, 234, 246);

	CommandTimerRenderer(DateTime startTime, DateTime endTime, double opacity)
	{
		this.startTime = startTime;
		this.endTime = endTime;
		this.opacity = opacity;
	}

	double get opacity
	{
		return _opacity;
	}

	set opacity(double value)
	{
		if(value == _opacity)
		{
			return;
		}
		_opacity = value;
	}

	DateTime get startTime
	{
		return _startTime;
	}

	set startTime(DateTime value)
	{
		if(value == _startTime)
		{
			return;
		}
		_startTime = value;
	}

	DateTime get endTime
	{
		return _endTime;
	}

	set endTime(DateTime value)
	{
		if(value == _endTime)
		{
			return;
		}
		_endTime = value;
	}

	@override
	bool get sizedByParent => true;
	
	@override
	bool hitTestSelf(Offset screenOffset) => true;

	@override
	void performResize() 
	{
		size = constraints.biggest;
	}

	@override
	void paint(PaintingContext context, Offset offset)
	{
		final Canvas canvas = context.canvas;

		DateTime now = new DateTime.now();
		double f = _endTime == null ? 1.0 : (now.difference(_startTime).inMilliseconds/_endTime.difference(_startTime).inMilliseconds).clamp(0.0, 1.0);
		double fi = 1.0-f;

		double dx = offset.dx;
		double width = size.width;
		const double IconSize = 15.0;
		const double Padding = 10.0;
		final double CenterY = offset.dy + size.height/2.0;
		int alpha = (255 * _opacity).round();
		if(alpha == 0)
		{
			return;
		}

		canvas.drawCircle(new Offset(dx+IconSize/2.0, CenterY), IconSize/2.0+1, new ui.Paint()
																								..color = Colors.white.withAlpha(alpha)
																								..style = PaintingStyle.stroke
																								..strokeWidth = 2.0);
		ui.Path hands = new ui.Path();
		hands.moveTo(dx + IconSize/2.0 - 4.0, CenterY+1);
		hands.lineTo(dx + IconSize/2.0, CenterY+1);
		hands.lineTo(dx + IconSize/2.0, CenterY-6.0);
		canvas.drawPath(hands, new ui.Paint()..color = Colors.white.withAlpha(alpha)
											..style = PaintingStyle.stroke
											..strokeWidth = 2.0);

		const double BarHeight = 12.0;
		
		dx += IconSize + Padding;
		width -= IconSize + Padding;

		String valueLabel = _endTime == null ? "N/A" : formatDuration(_endTime.difference(now));
		ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
			textAlign:TextAlign.start,
			fontFamily: "Roboto",
			fontSize: 19.0
		))..pushStyle(new ui.TextStyle(color:Colors.white));
		builder.addText(valueLabel);
		ui.Paragraph timeParagraph = builder.build();
		timeParagraph.layout(new ui.ParagraphConstraints(width:width/2));

		List<ui.TextBox> boxes = timeParagraph.getBoxesForRange(0, valueLabel.length);
		Size timeSize = new Size(boxes.last.right-boxes.first.left, boxes.last.bottom - boxes.first.top);
		canvas.drawParagraph(timeParagraph, new Offset(dx, CenterY - timeSize.height/2.0));

		dx += timeSize.width + Padding;
		width -= timeSize.width + Padding;

		Offset barOffset = new Offset(dx, CenterY - BarHeight/2.0);
		Offset barShadowOffset = new Offset(barOffset.dx + 4.0, barOffset.dy + 7.0);

		canvas.drawRRect(new RRect.fromRectAndRadius(barShadowOffset & new Size(width, BarHeight), const Radius.circular(6.0)), new ui.Paint()..color = new Color.fromARGB((48*_opacity.round()), 0, 19, 28));
		canvas.drawRRect(new RRect.fromRectAndRadius(barOffset & new Size(width, BarHeight), const Radius.circular(6.0)), new ui.Paint()..color = Colors.white.withAlpha(alpha));
		
		Color barColor;
		if(fi < 0.34)
		{
			barColor = angryTime.withAlpha(alpha);
		}
		else if(fi < 0.35)
		{
			double t = (0.35 - fi)*10*(10/1);
			barColor = Color.lerp(urgentTime, angryTime, t).withAlpha(alpha);
		}
		else if(fi < 0.74)
		{
			barColor = urgentTime.withAlpha(alpha);
		}
		else if(fi < 0.75)
		{
			double t = (0.75 - fi)*10*(10/1);
			barColor = Color.lerp(relaxedTime, urgentTime, t).withAlpha(alpha);
		}
		else
		{
			barColor = relaxedTime.withAlpha(alpha);
		}

		canvas.drawRRect(new RRect.fromRectAndRadius(barOffset & new Size(width*fi, BarHeight), const Radius.circular(6.0)), new ui.Paint()..color = barColor);
	}
}