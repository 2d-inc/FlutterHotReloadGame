import "package:flutter/material.dart";
import "dart:ui" as ui;
import "dart:math";
import "package:flare/flare.dart" as flr;
import "dart:typed_data";
import "package:flutter/scheduler.dart";

const double FEATURED_CORNER_RADIUS = 0.0;
const double FEATURED_RESTAURANT_SIZE = 0.0;
const double APP_PADDING = 20.0;
const String PIZZA_ICON = null;
const String BURGER_ICON = null;
const String DESSERT_ICON = null;

const Color BACKGROUND_COLOR = Colors.white;

enum IconType
{
	hidden,
	still,
	animated
}

const IconType CAROUSEL_ICON_TYPE = IconType.hidden;
const double MAIN_FONT_SIZE = 11.0;

class FeaturedRestaurantSimple extends StatelessWidget
{
	const FeaturedRestaurantSimple(this.name, 
	{
		Key key,
		this.description,
		this.deliveryTime,
		this.cornerRadius,
		this.iconType,
		this.fontSize,
		this.fontFamily
	}) : assert(name != null),
			super(key: key);
	
	final String name;
	final String description;
	final int deliveryTime;
	final double cornerRadius;
	final IconType iconType;
	final double fontSize;
	final String fontFamily;

	Widget build(BuildContext context) 
	{
		return new Container(
			padding:const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 10.0),
			width:160.0,
			child: new Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: <Widget>[
					new SizedBox(
						width:130.0, 
						height:130.0, 
						child:new Container(
							decoration:new BoxDecoration(
								border: new Border.all(
									color: Colors.black,
									width: 1.0,
								),
								borderRadius: new BorderRadius.circular(cornerRadius)
							)
						)
					),
					new Container(
						padding:const EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 5.0),
						child:new Text(name, 
							style:new TextStyle(fontFamily:fontFamily, fontSize:12.0,color:Colors.black, decoration: TextDecoration.none)),
					),
					new Text(description, 
						maxLines: 3,
						style:new TextStyle(fontFamily:fontFamily, fontSize:fontSize,color:Colors.black, decoration: TextDecoration.none)),
				]
			)
		);
	}
}

class FeaturedRestaurantAligned extends StatelessWidget
{
	const FeaturedRestaurantAligned(this.name, 
	{
		Key key,
		this.description,
		this.deliveryTime,
		this.cornerRadius,
		this.iconType,
		this.fontSize,
		this.fontFamily
	}) : assert(name != null),
			super(key: key);
	
	final String name;
	final String description;
	final int deliveryTime;
	final double cornerRadius;
	final IconType iconType;
	final double fontSize;
	final String fontFamily;
	
	Widget build(BuildContext context) 
	{
		return new Container(
			padding:const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 10.0),
			width:390.0,
			child: new Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: <Widget>[
					new SizedBox(
						width:375.0, 
						height:130.0, 
						child:new Container(
							decoration:new BoxDecoration(
								border: new Border.all(
									color: Colors.black,
									width: 1.0,
								),
								borderRadius: new BorderRadius.circular(cornerRadius)
							)
						)
					),
					
					new Container(
						padding:const EdgeInsets.fromLTRB(0.0, 10.0, 15.0, 5.0),
						child:new Row(
							children: <Widget>[
									new Expanded(
										child:new Text(name, style:new TextStyle(fontFamily:fontFamily, fontSize:17.0,color:Colors.black, decoration: TextDecoration.none)),
									),
									new Text("15 min", style:new TextStyle(fontFamily:fontFamily, fontSize:12.0,color:Colors.grey, decoration: TextDecoration.none)),
								],
							),
					),
					new Text(description, 
						maxLines: 3,
						style:new TextStyle(fontFamily:fontFamily, fontSize:fontSize, color:Colors.grey, decoration: TextDecoration.none)),
				]
			)
		);
	}
}

class FeaturedRestaurantData
{
	final String name;
	final String description;
	final int deliveryTime;
	final Color color;
	final String flare;
	
	const FeaturedRestaurantData(this.name,
		{
			this.description,
			this.deliveryTime,
			this.color,
			this.flare
		});
}

class FeaturedCarousel extends StatefulWidget 
{
	FeaturedCarousel({Key key, this.data, this.cornerRadius, this.iconType, this.fontSize, this.padding, this.fontFamily}) : super(key: key);

	final List<FeaturedRestaurantData> data;
	final double cornerRadius;
	final IconType iconType;
	final double fontSize;
	final double padding;
	final String fontFamily;

	@override
	_FeaturedCarouselState createState() => new _FeaturedCarouselState(data);
}

class _FeaturedCarouselState extends State<FeaturedCarousel> with SingleTickerProviderStateMixin
{
	AnimationController _controller;
	Animation<double> _slideAnimation;
	double scroll = 0.0;

	final List<FeaturedRestaurantData> data;

	_FeaturedCarouselState(this.data);
	
	void dragStart(DragStartDetails details)
	{
		_controller.stop();
	}

	void dragUpdate(DragUpdateDetails details)
	{
		setState(()
		{
			scroll += details.delta.dx/context.size.width;
		});
	}

	void dragEnd(DragEndDetails details)
	{
		_slideAnimation = new Tween<double>(
			begin: scroll,
			end: -min((data.length-1).toDouble(), max(0.0, -scroll.roundToDouble()))
		).animate(_controller);
	
		_controller
			..value = 0.0
			..fling(velocity: details.velocity.pixelsPerSecond.distance / 1000.0);
	}

	initState() 
	{
    	super.initState();
    	_controller = new AnimationController(vsync: this);
		_controller.addListener(()
		{
			setState(()
			{
				scroll = _slideAnimation.value;
			});
		});
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
		List<Widget> visibleHeros = <Widget>[];
		List<Widget> visibleDetails = <Widget>[];

		int visibleIdx = -(scroll.truncate());
		double scrollFactor = scroll - scroll.truncateToDouble();

		for(int i = -1; i < 2; i++)
		{
			int idx = visibleIdx+i;
			if(idx < 0 || idx >= data.length)
			{
				continue;
			}
			FeaturedRestaurantData restaurant = data[visibleIdx+i];
			//visibleHeros.add(new RepaintBoundary(child:new RestaurantHero(color:restaurant.color, scroll:scrollFactor+i, flare:restaurant.flare)));
			visibleHeros.add(new RestaurantHero(color:restaurant.color, scroll:scrollFactor+i, flare:restaurant.flare, iconType:widget.iconType));
			visibleDetails.add(new FeaturedRestaurantDetail(restaurant.name, description:restaurant.description, scroll:scrollFactor+i, deliveryTime: restaurant.deliveryTime, cornerRadius:widget.cornerRadius, fontSize:widget.fontSize, padding:widget.padding, fontFamily:widget.fontFamily));
		}

		if(visibleDetails.length == 0)
		{
			return new Container();
		}
		
		return new GestureDetector(
			onHorizontalDragStart: dragStart,
			onHorizontalDragUpdate: dragUpdate,
			onHorizontalDragEnd: dragEnd,
			child: new Stack(
				children:visibleHeros + visibleDetails
			)
		);
	}
}


class FeaturedRestaurantDetail extends LeafRenderObjectWidget
{
	final String name;
	final String description;
	final int deliveryTime;
	final double scroll;
	final double cornerRadius;
	final double fontSize;
	final double padding;
	final String fontFamily;

	FeaturedRestaurantDetail(this.name,
		{
			Key key, 
			this.description,
			this.deliveryTime,
			this.scroll = 0.0,
			this.cornerRadius,
			this.fontSize,
			this.padding,
			this.fontFamily
		}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new FeaturedRestaurantDetailRenderObject(name,
					description:description,
					deliveryTime:deliveryTime,
					scroll:scroll,
					cornerRadius:cornerRadius,
					fontSize:fontSize,
					padding:padding,
					fontFamily:fontFamily);
	}

	@override
	void updateRenderObject(BuildContext context, covariant FeaturedRestaurantDetailRenderObject renderObject)
	{
		renderObject..name = name
					..description = description
					..deliveryTime = deliveryTime
					..scroll = scroll
					..cornerRadius = cornerRadius
					..fontSize = fontSize
					..padding = padding
					..fontFamily = fontFamily;
	}
}
const double Padding = 20.0;
const double ItemPadding = 10.0;
const double DetailHeight = 109.0;
const double DetailPaddingLeft = 18.0;
const double DetailPaddingTop = 15.0;
const double TimePaddingTop = 20.0;
const double DescriptionPaddingTop = 49.0;

final MaskFilter _kShadowMaskFilter = new MaskFilter.blur(BlurStyle.normal, BoxShadow.convertRadiusToSigma(24.0));

class FeaturedRestaurantDetailRenderObject extends RenderBox
{
	String _name;
	String _description;
	int _deliveryTime;
	double _scroll;
	double _cornerRadius;
	double _fontSize;
	double _padding;
	String _fontFamily;

	ui.Paragraph _nameParagraph;
	ui.Paragraph _timeParagraph;
	ui.Paragraph _descriptionParagraph;
	double _actualTimeWidth;
	String _deliveryTimeLabel;

	FeaturedRestaurantDetailRenderObject(String name,
		{
			String description = "",
			int deliveryTime = 0,
			double scroll = 0.0,
			double cornerRadius = 0.0,
			double fontSize = 11.0,
			double padding = 15.0,
			String fontFamily = null
		})
	{
		this.fontSize = fontSize;
		this.name = name;
		this.description = description;	
		this.deliveryTime = deliveryTime;
		this.cornerRadius = _cornerRadius;
		this.padding = padding;
		this.fontFamily = fontFamily;
		_scroll = scroll;
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
	void performLayout()
	{
		super.performLayout();

		final double detailsTextMaxWidth = size.width - Padding*2 - DetailPaddingLeft*2.0;

		ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
			textAlign:TextAlign.start,
			fontFamily: fontFamily,
			fontSize: 20.0,
			fontWeight: FontWeight.w500
		))..pushStyle(new ui.TextStyle(color:Colors.black));
		builder.addText(_name);
		_nameParagraph = builder.build();

		_timeParagraph.layout(new ui.ParagraphConstraints(width: detailsTextMaxWidth/2.0));

		// Calculate actual (to the glyph) width consumed by the delivery time label.
		List<ui.TextBox> boxes = _timeParagraph.getBoxesForRange(0, _deliveryTimeLabel.length);
		_actualTimeWidth = boxes.last.right-boxes.first.left;

		// Use that to calculate available remaining space for the title.
		_nameParagraph.layout(new ui.ParagraphConstraints(width: detailsTextMaxWidth - _actualTimeWidth));

		_descriptionParagraph.layout(new ui.ParagraphConstraints(width: detailsTextMaxWidth));
	}
	
	@override
	void paint(PaintingContext context, Offset offset)
	{
		final double renderPadding = (_padding ?? 10.0) + 5;
		final double width = size.width - renderPadding*2;
		final Canvas canvas = context.canvas;
		canvas.save();
		canvas.translate(_scroll * (width+ItemPadding), size.height-DetailHeight);

		//print("CIRC $offset.dx+$Padding, $offset.dy) & new Size($width, $DetailHeight), new Radius.circular($_cornerRadius");
    	final RRect rrect = new RRect.fromRectAndRadius(new Offset(offset.dx+renderPadding, offset.dy) & new Size(width, DetailHeight), new Radius.circular(_cornerRadius ?? 0.0));
		canvas.drawRRect(rrect, new ui.Paint()..color = Colors.white);
		
		canvas.drawParagraph(_nameParagraph, new Offset(offset.dx+renderPadding+DetailPaddingLeft, offset.dy + DetailPaddingTop));
		canvas.drawParagraph(_timeParagraph, new Offset(offset.dx+renderPadding+width-DetailPaddingLeft - _actualTimeWidth, offset.dy + TimePaddingTop));
		canvas.drawParagraph(_descriptionParagraph, new Offset(offset.dx+renderPadding+DetailPaddingLeft, offset.dy + DescriptionPaddingTop));
		
		canvas.restore();
	}

	String get name
	{
		return _name;
	}

	set name(String value)
	{
		if(_name == value)
		{
			return;
		}
		_name = value ?? "";

		markNeedsLayout();
		markNeedsPaint();
	}

	String get fontFamily
	{
		return _fontFamily;
	}

	set fontFamily(String value)
	{
		if(_fontFamily == value)
		{
			return;
		}
		_fontFamily = value;
	
		markNeedsLayout();
		markNeedsPaint();
	}

	String get description
	{
		return _description;
	}

	void updateDescription()
	{
		ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
			textAlign:TextAlign.start,
			fontFamily: "Roboto",
			fontSize: _fontSize,
			maxLines: 2,
			ellipsis: "..."
		))..pushStyle(new ui.TextStyle(color:new Color.fromARGB(102, 48, 44, 72)));
		builder.addText(_description);
		_descriptionParagraph = builder.build();
	}

	set description(String value)
	{
		if(_description == value)
		{
			return;
		}
		_description = value ?? "";

		updateDescription();

		markNeedsLayout();
		markNeedsPaint();
	}

	int get deliveryTime
	{
		return _deliveryTime;
	}

	set deliveryTime(int value)
	{
		if(_deliveryTime == value)
		{
			return;
		}
		_deliveryTime = value ?? 0;

		ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
			textAlign:TextAlign.left,
			fontFamily: "Roboto",
			fontSize: 15.0
		))..pushStyle(new ui.TextStyle(color:new Color.fromARGB(102, 48, 44, 72)));
		builder.addText((_deliveryTimeLabel=_deliveryTime.toString() + " min"));
		_timeParagraph = builder.build();
		
		markNeedsLayout();
		markNeedsPaint();
	}
	
	double get padding
	{
		return _padding;
	}

	set padding(double value)
	{
		if(_padding == value)
		{
			return;
		}
		_padding = value;
		markNeedsPaint();
	}

	double get scroll
	{
		return _scroll;
	}

	set scroll(double value)
	{
		if(_scroll == value)
		{
			return;
		}
		_scroll = value;
		markNeedsPaint();
	}
	
	double get cornerRadius
	{
		return _cornerRadius;
	}

	set cornerRadius(double value)
	{
		if(_cornerRadius == value)
		{
			return;
		}
		_cornerRadius = value;
		markNeedsPaint();
	}
	
	double get fontSize
	{
		return _fontSize;
	}

	set fontSize(double value)
	{
		if(_fontSize == value)
		{
			return;
		}
		_fontSize = value;
		updateDescription();
		markNeedsLayout();
		markNeedsPaint();
	}
}

class RestaurantHero extends LeafRenderObjectWidget
{
	final Color color;
	final String flare;
	final double scroll;
	final IconType iconType;

	RestaurantHero(
		{
			Key key, 
			this.color,
			this.flare,
			this.scroll = 0.0,
			this.iconType
		}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new RestaurantHeroRenderObject(
					color:color,
					flare:flare,
					scroll:scroll,
					iconType:iconType);
	}

	@override
	void updateRenderObject(BuildContext context, covariant RestaurantHeroRenderObject renderObject)
	{
		renderObject..color = color
					..flare = flare
					..scroll = scroll
					..iconType = iconType;
	}

	@override
	void didUnmountRenderObject(RestaurantHeroRenderObject renderObject)
	{
		renderObject.cleanup();
	}
}

class RestaurantHeroRenderObject extends RenderBox
{
	Color _color;
	String _flare;
	Rect _flareRect = Rect.zero;
	double _scroll = 0.0;
	flr.FlutterActor _actor;
	flr.ActorAnimation _animation;

	double _animationTime = 0.0;
	double _lastFrameTime = 0.0;
	bool _isPlaying = false;
	IconType _iconType = IconType.hidden;

	set isPlaying(bool play)
	{
		if(_isPlaying == play)
		{
			return;
		}
		_isPlaying = play;
		if(play)
		{
			_lastFrameTime = new DateTime.now().microsecondsSinceEpoch / Duration.microsecondsPerMillisecond / 1000.0;
			SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
		}
	}

	cleanup()
	{
		isPlaying = false;
	}

	bool get isPlaying
	{
		return _isPlaying;
	}

	void beginFrame(Duration timeStamp) 
	{
		//final double t = timeStamp.inMicroseconds / Duration.microsecondsPerMillisecond / 1000.0;
		final double t = new DateTime.now().microsecondsSinceEpoch / Duration.microsecondsPerMillisecond / 1000.0;

		double elapsed = t - _lastFrameTime;
		_lastFrameTime = t;
		
		if(_actor != null)
		{
			if(_iconType == IconType.animated)
			{
				_animationTime += elapsed;
			}
			
			if(_animation != null)
			{
				_animation.apply(_animationTime%_animation.duration, _actor, 1.0);
			}
			_actor.advance(elapsed);
		}

		markNeedsPaint();
		if(_isPlaying)
		{
			SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
		}
	}

	RestaurantHeroRenderObject(
		{
			Color color,
			String flare,
			double scroll = 0.0,
			IconType iconType
		})
	{
		_color = color;	
		this.flare = flare;	
		_scroll = scroll;
		this.iconType = iconType;
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

	// @override
	// void performLayout()
	// {
	// 	super.performLayout();
		
	// 	if(_actor != null)
	// 	{
	// 	}
	// }

	@override
	void paint(PaintingContext context, Offset offset)
	{
		final Canvas canvas = context.canvas;

		// Draw bg & Flare
		canvas.save();
		canvas.translate(_scroll * size.width, 0.0);
		canvas.drawRect(offset & new Size(size.width, size.height-DetailHeight/2.0), new ui.Paint()..color = _color);
		canvas.restore();


		// Draw Shadow
		final double width = size.width - Padding*2;
		canvas.save();
		canvas.translate(_scroll * (width+ItemPadding), size.height-DetailHeight);
    	final RRect rrect = new RRect.fromRectAndRadius(new Offset(offset.dx+Padding, offset.dy) & new Size(width, DetailHeight), const Radius.circular(10.0));
		canvas.drawRRect(rrect.shift(const Offset(0.0, 20.0)), new ui.Paint()
			..color = new Color.fromARGB(22, 0, 35, 120)
			..maskFilter = _kShadowMaskFilter);
		canvas.restore();

		const double verticalOffset = -75.0;
		
		if(_actor != null && _iconType != IconType.hidden)
		{
			canvas.save();
			canvas.translate(_scroll * (width+ItemPadding), 0.0);
			canvas.translate(size.width/2.0-_flareRect.left-_flareRect.width/2.0, (size.height-DetailHeight/2.0)/2.0-_flareRect.top-_flareRect.height/2.0+verticalOffset);
			_actor.draw(canvas);
			canvas.restore();
		}
	}

	IconType get iconType
	{
		return _iconType;
	}

	set iconType(IconType type)
	{
		if(_iconType == type)
		{
			return;
		}
		_iconType = type;
		if(type == IconType.still)
		{
			_animationTime = 0.0;
		}
		markNeedsPaint();
	}

	Color get color
	{
		return _color;
	}

	set color(Color value)
	{
		if(_color == value)
		{
			return;
		}
		_color = value;
		markNeedsPaint();
	}

	String get flare
	{
		return _flare;
	}

	set flare(String value)
	{
		if(_flare == value)
		{
			return;
		}
		_flare = value;
		_animation = null;
		updateShouldPlay();

		if(value == null)
		{
			markNeedsPaint();
			return;
		}
		flr.FlutterActor actor = new flr.FlutterActor();
		// actor = new FlutterActor();
		actor.loadFromBundle(value).then(
			(bool success)
			{
				_actor = actor;
				_animation = actor.getAnimation("Feature");
				// if(_animation != null)
				// {
				// 	_animation.apply(0.0, _actor, 1.0);
				// }
				_actor.advance(0.0);
				Float32List aabb = _actor.computeAABB();
				if(value == "assets/flares/Sushi")
				{
					_flareRect = new Rect.fromLTRB(aabb[0]+300.0, aabb[1]-100, aabb[2], aabb[3]);
				}
				else
				{
					_flareRect = new Rect.fromLTRB(aabb[0], aabb[1], aabb[2], aabb[3]);
				}

				if(_animation != null)
				{
					_animation.apply(0.0, _actor, 1.0);
					_actor.advance(0.0);
				}
				
				markNeedsPaint();
				updateShouldPlay();
				//animation = actor.getAnimation("Run");
			}
		);
	}

	void updateShouldPlay()
	{
		isPlaying = _animation != null && _scroll == 0.0;//> -1.0 && _scroll < 1.0;
	}

	double get scroll
	{
		return _scroll;
	}

	set scroll(double value)
	{
		if(_scroll == value)
		{
			return;
		}
		_scroll = value;
		updateShouldPlay();
		markNeedsPaint();
	}
}
