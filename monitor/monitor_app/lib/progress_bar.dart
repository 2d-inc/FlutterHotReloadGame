import "package:flutter/material.dart";
import "dart:ui" as ui;

class ProgressBar extends LeafRenderObjectWidget
{
    final double _progress;

    ProgressBar(this._progress, {Key key}) : super(key:key);

    @override
    RenderObject createRenderObject(BuildContext context) => new ProgressRenderer(_progress);

    @override
    void updateRenderObject(BuildContext context, ProgressRenderer renderObject)
    {
        renderObject..progress = _progress;
    }
}

class ProgressRenderer extends RenderBox
{
    double _progress;

    ProgressRenderer(this._progress);

    set progress(double v)
    {
        if(v != _progress)
        {
            _progress = v;
            markNeedsLayout();
            markNeedsPaint();
        }
    }

    @override
    bool get sizedByParent => true;

    @override
    bool hitTestSelf(Offset screenOffset) => true;

    @override
    void performResize() => size = constraints.biggest;

    @override
    void paint(PaintingContext context, Offset offset)
    {
        final Canvas canvas = context.canvas;

        const int numTicks = 8;
        const double width = 490.0;
        const double height = 12.1;
        const Size barSize = const Size(width, height);    

        Offset shadowOffset = new Offset(offset.dx + 4, offset.dy + 7);
        canvas.drawRRect(new RRect.fromRectAndRadius(shadowOffset&barSize, const Radius.circular(6.0)), new Paint()..color = const Color.fromARGB(48, 0, 19, 28));
        canvas.drawRRect(new RRect.fromRectAndRadius(offset&barSize, const Radius.circular(6.0)), new Paint()..color = Colors.white);
        Size fillSize = new Size(width*_progress, height);
        canvas.drawRRect(new RRect.fromRectAndRadius(offset&fillSize, const Radius.circular(6.0)), new Paint()..color = new Color.fromRGBO(13, 129, 181, 1.0));

        const double tickDistance = (width - 13)/(numTicks);
        double xOffset = offset.dx + 5.0;
        double numHighlightedTicks = numTicks * _progress;
        for(int i = 0; i < numTicks+1; i++)
        {
            Offset tickOffset = new Offset(xOffset + i * tickDistance, offset.dy + height);
            const Size tick = const Size(3.0, 5.0);
            bool isHighlighted = _progress > 0 && i <= numHighlightedTicks;
            canvas.drawRect(tickOffset&tick, new Paint()..color = isHighlighted ? const Color.fromRGBO(13, 129, 181, 1.0) : Color.fromRGBO(255,255,255, 0.2));
        }

    }
}
