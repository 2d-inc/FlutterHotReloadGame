import "package:flutter/material.dart";
import "dart:ui" as ui;
import "dart:math";

class FeaturedRestaurantSimple extends StatelessWidget
{
	const FeaturedRestaurantSimple(this.name, 
	{
		Key key,
		this.description,
		this.deliveryTime
	}) : assert(name != null),
			super(key: key);
	
	final String name;
	final String description;
	final int deliveryTime;
	
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
							)
						)
					),
					new Container(
						padding:const EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 5.0),
						child:new Text(name, 
							style:const TextStyle(fontSize:12.0,color:Colors.black, decoration: TextDecoration.none)),
					),
					new Text(description, 
						maxLines: 3,
						style:const TextStyle(fontSize:11.0,color:Colors.black, decoration: TextDecoration.none)),
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
		this.deliveryTime
	}) : assert(name != null),
			super(key: key);
	
	final String name;
	final String description;
	final int deliveryTime;
	
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
							)
						)
					),
					
					new Container(
						padding:const EdgeInsets.fromLTRB(0.0, 10.0, 15.0, 5.0),
						child:new Row(
							children: <Widget>[
									new Expanded(
										child:new Text(name, style:const TextStyle(fontSize:17.0,color:Colors.black, decoration: TextDecoration.none)),
									),
									new Text("15 min", style:const TextStyle(fontSize:12.0,color:Colors.grey, decoration: TextDecoration.none)),
								],
							),
					),
					new Text(description, 
						maxLines: 3,
						style:const TextStyle(fontSize:12.0,color:Colors.grey, decoration: TextDecoration.none)),
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
	FeaturedCarousel({Key key, this.data}) : super(key: key);

	final List<FeaturedRestaurantData> data;

	@override
	_FeaturedCarouselState createState() => new _FeaturedCarouselState(data);
}

class _FeaturedCarouselState extends State<FeaturedCarousel>  with SingleTickerProviderStateMixin
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
			visibleHeros.add(new RestaurantHero(color:restaurant.color, scroll:scrollFactor+i));
			visibleDetails.add(new FeaturedRestaurantDetail(restaurant.name, description:restaurant.description, scroll:scrollFactor+i));
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

	FeaturedRestaurantDetail(this.name,
		{
			Key key, 
			this.description,
			this.deliveryTime,
			this.scroll = 0.0
		}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new FeaturedRestaurantDetailRenderObject(name,
					description:description,
					deliveryTime:deliveryTime,
					scroll:scroll);
	}

	@override
	void updateRenderObject(BuildContext context, covariant FeaturedRestaurantDetailRenderObject renderObject)
	{
		renderObject..name = name
					..description = description
					..deliveryTime = deliveryTime
					..scroll = scroll;
	}
}
const double Padding = 20.0;
const double ItemPadding = 10.0;
const double DetailHeight = 109.0;
final MaskFilter ShadowMaskFilter = new MaskFilter.blur(BlurStyle.normal, BoxShadow.convertRadiusToSigma(24.0));

class FeaturedRestaurantDetailRenderObject extends RenderBox
{
	String _name;
	String _description;
	int _deliveryTime;
	double _scroll;

	FeaturedRestaurantDetailRenderObject(String name,
		{
			String description,
			int deliveryTime,
			double scroll = 0.0
		})
	{
		_name = name;
		_description = description;	
		_deliveryTime = deliveryTime;
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
	void paint(PaintingContext context, Offset offset)
	{
		final double width = size.width - Padding*2;
		final Canvas canvas = context.canvas;
		canvas.save();
		canvas.translate(_scroll * (width+ItemPadding), size.height-DetailHeight);
    	final RRect rrect = new RRect.fromRectAndRadius(new Offset(offset.dx+Padding, offset.dy) & new Size(width, DetailHeight), const Radius.circular(10.0));
		canvas.drawRRect(rrect, new ui.Paint()..color = Colors.white);
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
		_name = value;
		markNeedsPaint();
	}

	String get description
	{
		return _description;
	}

	set description(String value)
	{
		if(_description == value)
		{
			return;
		}
		_description = value;
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
		_deliveryTime = value;
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
}

class RestaurantHero extends LeafRenderObjectWidget
{
	final Color color;
	final String flare;
	final double scroll;

	RestaurantHero(
		{
			Key key, 
			this.color,
			this.flare,
			this.scroll = 0.0
		}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new RestaurantHeroRenderObject(
					color:color,
					flare:flare,
					scroll:scroll);
	}

	@override
	void updateRenderObject(BuildContext context, covariant RestaurantHeroRenderObject renderObject)
	{
		renderObject..color = color
					..flare = flare
					..scroll = scroll;
	}
}

class RestaurantHeroRenderObject extends RenderBox
{
	Color _color;
	String _flare;
	double _scroll;

	RestaurantHeroRenderObject(
		{
			Color color,
			String flare,
			double scroll = 0.0
		})
	{
		_color = color;	
		_flare = flare;	
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
			..color = new Color.fromARGB(100, 0, 35, 120)
			..maskFilter = ShadowMaskFilter);

		canvas.restore();
		
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
}
