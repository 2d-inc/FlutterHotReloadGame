import "dart:math";
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';


class DottedRowDecoration extends Decoration
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