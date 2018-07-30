import "package:flutter/material.dart";

/// This is the progress bar shown in the main [Monitor] widget.
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

/// This custom renderer for the widget above is used to draw a custom rounded rectangle with a shadow
/// below it, and its 8 ticks.
/// As the game progresses and tasks are completed, the Simulator App will appear more and more complete,
/// and this progress bar will fill up as a consequence.
/// The [MonitorState] will pass in the [_progress] value.
class ProgressRenderer extends RenderBox
{
    static const int numTicks = 8;
    static const double width = 490.0;
    static const double height = 12.1;
    static const double tickDistance = (width - 13)/(numTicks);
    static const Size tick = const Size(3.0, 5.0);
    static const Size barSize = const Size(ProgressRenderer.width, ProgressRenderer.height);

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
    bool get sizedByParent => false;

    @override
    bool hitTestSelf(Offset screenOffset) => true;

    @override
    void performResize() => size = new Size(ProgressRenderer.width, ProgressRenderer.height);

    @override
    void performLayout() 
    {
        size = new Size(ProgressRenderer.width, ProgressRenderer.height);
    }

    @override
    void paint(PaintingContext context, Offset offset)
    {
        final Canvas canvas = context.canvas;

        /// Draws the shadow with a slight offset from the actual bar position.
        Offset shadowOffset = new Offset(offset.dx + 4, offset.dy + 7);
        canvas.drawRRect(new RRect.fromRectAndRadius(shadowOffset&barSize, const Radius.circular(6.0)), new Paint()..color = const Color.fromARGB(48, 0, 19, 28));
        /// Draw the white progress bar.
        canvas.drawRRect(new RRect.fromRectAndRadius(offset&barSize, const Radius.circular(6.0)), new Paint()..color = Colors.white);
        /// Calculate which percentage of the progress bar has been filled up and draw it.
        Size fillSize = new Size(width*_progress, height);
        canvas.drawRRect(new RRect.fromRectAndRadius(offset&fillSize, const Radius.circular(6.0)), new Paint()..color = new Color.fromRGBO(13, 129, 181, 1.0));

        double xOffset = offset.dx + 5.0;
        double numHighlightedTicks = numTicks * _progress;
        /// Also draw the ticks, either highlighted or not.
        for(int i = 0; i < numTicks+1; i++)
        {
            Offset tickOffset = new Offset(xOffset + i * tickDistance, offset.dy + height);
            bool isHighlighted = _progress > 0 && i <= numHighlightedTicks;
            canvas.drawRect(tickOffset&tick, new Paint()..color = isHighlighted ? const Color.fromRGBO(13, 129, 181, 1.0) : Color.fromRGBO(255,255,255, 0.2));
        }

    }
}
