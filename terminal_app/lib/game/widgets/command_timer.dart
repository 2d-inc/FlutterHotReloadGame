import "dart:ui" as ui;

import 'package:flutter/material.dart';

import "../decorations/game_colors.dart";

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

/// This [RenderBox] displays the Timer on top of the stakeholder to display the current command timer
/// as it runs out. It'll fade from blue, to yellow, to red as time passes.
/// These thresholds match the time at which the stakeholder will change its animation from "happy", to 
/// "upset", to "angry".
class CommandTimerRenderer extends RenderBox
{
    static const double IconSize = 15.0;
	static const double Padding = 10.0;
    static const double BarHeight = 12.0;
    static const Radius BarRadius = const Radius.circular(6.0);

	DateTime _startTime;
	DateTime _endTime;
	double _opacity;

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
		
		final double centerY = offset.dy + size.height/2.0;
		int alpha = (255 * _opacity).round();
		if(alpha == 0)
		{
			return;
		}

        /// Draw the small circle before the actual timer.
		canvas.drawCircle(new Offset(dx+IconSize/2.0, centerY), IconSize/2.0+1, new ui.Paint()
																								..color = Colors.white.withAlpha(alpha)
																								..style = PaintingStyle.stroke
																								..strokeWidth = 2.0);
        /// Manually draw the two clock hands as a decoration for the circle.
		ui.Path hands = new ui.Path();
		hands.moveTo(dx + IconSize/2.0 - 4.0, centerY+1);
		hands.lineTo(dx + IconSize/2.0, centerY+1);
		hands.lineTo(dx + IconSize/2.0, centerY-6.0);
		canvas.drawPath(hands, new ui.Paint()..color = Colors.white.withAlpha(alpha)
											..style = PaintingStyle.stroke
											..strokeWidth = 2.0);

		
		dx += IconSize + Padding;
		width -= IconSize + Padding;

        /// If a time has been supplied and the timer has not run out, a label is displayed with how much time is left
        /// for this command before a life is lost. 
        /// Otherwise show "N/A".
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
		canvas.drawParagraph(timeParagraph, new Offset(dx, centerY - timeSize.height/2.0));

		dx += timeSize.width + Padding;
		width -= timeSize.width + Padding;

		Offset barOffset = new Offset(dx, centerY - BarHeight/2.0);
		Offset barShadowOffset = new Offset(barOffset.dx + 4.0, barOffset.dy + 7.0);

        /// First draw a semi-transparent black Rounded Rectangle so that the timer bar will have a simple shadow.
		canvas.drawRRect(new RRect.fromRectAndRadius(barShadowOffset & new Size(width, BarHeight), BarRadius), new ui.Paint()..color = new Color.fromARGB((48*_opacity.round()), 0, 19, 28));
        /// Second draw a white Rounded Rectangle on top of the shadow for the timer's background.
		canvas.drawRRect(new RRect.fromRectAndRadius(barOffset & new Size(width, BarHeight), BarRadius), new ui.Paint()..color = Colors.white.withAlpha(alpha));
		
        /// Lastly, there'll be a third bar on top of the white background which'll display the time left for the current command.
        /// Evaluate its color depending on how much time is left, and lerp between one state and the other.
		Color barColor;
		if(fi < 0.34)
		{
			barColor = GameColors.angryTime.withAlpha(alpha);
		}
		else if(fi < 0.35)
		{
			double t = (0.35 - fi)*10*(10/1);
			barColor = Color.lerp(GameColors.urgentTime, GameColors.angryTime, t).withAlpha(alpha);
		}
		else if(fi < 0.74)
		{
			barColor = GameColors.urgentTime.withAlpha(alpha);
		}
		else if(fi < 0.75)
		{
			double t = (0.75 - fi)*10*(10/1);
			barColor = Color.lerp(GameColors.relaxedTime, GameColors.urgentTime, t).withAlpha(alpha);
		}
		else
		{
			barColor = GameColors.relaxedTime.withAlpha(alpha);
		}

		canvas.drawRRect(new RRect.fromRectAndRadius(barOffset & new Size(width*fi, BarHeight), BarRadius), new ui.Paint()..color = barColor);
	}
}