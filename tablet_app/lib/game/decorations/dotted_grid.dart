import 'dart:ui' show PointMode;

import "package:flutter/material.dart";

class DottedGrid extends Decoration
{
    @override
    BoxPainter createBoxPainter([VoidCallback onChanged])
    {
        return new DottedGridPainter();
    }
}

/// Custom decoration that draws a list of dots directly on the [Canvas].
class DottedGridPainter extends BoxPainter
{
    static const double spacingWidth = 22.0;
    static const double spacingHeight = 17.0;
    static const double phase = 0.8;

    @override
    void paint(Canvas canvas, Offset offset, ImageConfiguration configuration)
    {
        int numCols = (configuration.size.width / spacingWidth).ceil()+1;
        int numRows = (configuration.size.height / spacingHeight).ceil()+1;
        int numPoints = numCols*numRows;
        Paint dotsPaint = new Paint()
            ..strokeWidth = 1.0
            ..color = const Color.fromARGB(120, 255, 255, 255);

        List<Offset> dots = new List(numPoints);
        
        int idx = 0;
        double startY = offset.dy  - phase*spacingHeight;
        double startX = offset.dx  - phase*spacingWidth;
        for(int y = 0; y < numRows; y++)
        {
            double dy = startY + y * spacingHeight;
            for(int x = 0; x < numCols; x++)
            {
                dots[idx++] = new Offset(startX + x * spacingWidth, dy);
            }
        }
        canvas.save();
        canvas.clipRect(offset & configuration.size);
        canvas.drawRect(offset & configuration.size, new Paint()..color = Colors.black);
        canvas.drawPoints(PointMode.points, dots, dotsPaint);
        canvas.restore();
    }
}