import 'package:flutter/material.dart';
import "dart:math";
import "dart:ui" as ui;

class RestaurantsHeaderSimple extends StatelessWidget
{
	Widget build(BuildContext context)
	{
		return new Container(
			padding:const EdgeInsets.fromLTRB(20.0, 5.0, 0.0, 10.0),
			child:new Text("Nearby\n1600 Amphitheater Pkwy", 
				style:const TextStyle(fontSize:12.0,color:Colors.black, decoration: TextDecoration.none)),
		);
	}
}

class RestaurantsHeaderAligned extends StatelessWidget
{
	Widget build(BuildContext context)
	{
		return new Container(
			padding:const EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 10.0),
			child:new Row(
				children: <Widget>[
					new Expanded(child:new Text("NEARBY", style:const TextStyle(fontSize:12.0,color:Colors.grey, decoration: TextDecoration.none))),
					new Text("1600 Amphitheater Pkwy", style:const TextStyle(fontSize:12.0,color:Colors.black, decoration: TextDecoration.none)),
				]
			)
		);
	}
}

class RestaurantSimple extends StatelessWidget
{
	const RestaurantSimple(this.name, 
	{
		Key key,
		this.description,
		this.dollarSigns,
		this.deliveryTime,
		this.rating
	}) : assert(name != null),
			super(key: key);
	
	final String name;
	final String description;
	final int dollarSigns;
	final int deliveryTime;
	final int rating;
	
	Widget build(BuildContext context) 
	{
		return new Container(
			padding:const EdgeInsets.fromLTRB(20.0, 0.0, 0.0, 10.0),
			child: new Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: <Widget>[
					new SizedBox(
						width:100.0, 
						height:100.0, 
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
						padding:const EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 0.0),
						child:new Text("Restaurant Name", 
							style:const TextStyle(fontSize:10.0,color:Colors.black, decoration: TextDecoration.none)),
					),
					new Text("Description", 
						style:const TextStyle(fontSize:10.0,color:Colors.black, decoration: TextDecoration.none)),
					new Text("0/10", 
						style:const TextStyle(fontSize:10.0,color:Colors.black, decoration: TextDecoration.none)),
					new Text("\$"*5, 
						style:const TextStyle(fontSize:10.0,color:Colors.black, decoration: TextDecoration.none)),
					new Text("0 min", 
						style:const TextStyle(fontSize:10.0,color:Colors.black, decoration: TextDecoration.none)),
				]
			)
		);
	}
}

class RestaurantAligned extends StatelessWidget
{
	const RestaurantAligned(this.name, 
	{
		Key key,
		this.description,
		this.dollarSigns,
		this.deliveryTime,
		this.rating
	}) : assert(name != null),
			super(key: key);
	
	final String name;
	final String description;
	final int dollarSigns;
	final int deliveryTime;
	final int rating;
	
	Widget build(BuildContext context) 
	{
		return new Container(
			padding:const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 10.0),
			child: new Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: <Widget>[
					new SizedBox(
						width:100.0, 
						height:100.0, 
						child:new Container(
							decoration:new BoxDecoration(
								border: new Border.all(
									color: Colors.black,
									width: 1.0,
								),
							)
						)
					),
					new Expanded(
						child:new Container(
							padding: new EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 0.0),
							child:new Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: <Widget>[
									new Container(
										padding:const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 4.0),
										child:new Text(name, 
											style:const TextStyle(fontSize:14.0,color:Colors.black, decoration: TextDecoration.none)),
									),
									new Container(
										padding:const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 12.0),
										child:new Text(description, 
											style:const TextStyle(fontSize:12.0,color:Colors.grey, decoration: TextDecoration.none)),
									),
									new Row(
										children:<Widget>[
											new Expanded(child:new Text(rating.round().toString() + "/10", style:const TextStyle(fontSize:13.0,color:Colors.grey, decoration: TextDecoration.none))),
											new Expanded(child:new Text("\$"*min(dollarSigns,5), style:const TextStyle(fontSize:13.0,color:Colors.black, decoration: TextDecoration.none))),
											new Text(deliveryTime.toString() + " min", 
												style:const TextStyle(fontSize:13.0,color:Colors.grey, decoration: TextDecoration.none)),
										]
									)
								]
							)
						)
					)
				]
			)
		);
	}
}

class RestaurantDesigned extends StatelessWidget
{
	const RestaurantDesigned(this.name, 
	{
		Key key,
		this.description,
		this.dollarSigns,
		this.deliveryTime,
		this.rating,
		this.img
	}) : assert(name != null),
			super(key: key);
	
	final String name;
	final String description;
	final String img;
	final int dollarSigns;
	final int deliveryTime;
	final int rating;
	
	Widget build(BuildContext context) 
	{
		return new Container(
			padding:const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
			child:new Container(
				decoration: new BoxDecoration(
					color:Colors.white, 
					borderRadius: const BorderRadius.all(const Radius.circular(10.0)),
					boxShadow: <BoxShadow>[
						new BoxShadow(
            				color: const Color.fromARGB(22, 0, 35, 120),
            				blurRadius: 24.0,
          				)
					]
				),
				child: new Row(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: <Widget>[
						new Container(
							width:100.0,
							height:100.0,
							decoration: new BoxDecoration(
								borderRadius: const BorderRadius.only(topLeft:const Radius.circular(10.0), bottomLeft:const Radius.circular(10.0)),
								
								image: new DecorationImage(
									image: new ExactAssetImage("assets/images/cafe.jpg"),
									fit: BoxFit.cover,
									alignment: Alignment.center
									
								),
							)
						),
						new Expanded(
							child:new Container(
								padding: new EdgeInsets.fromLTRB(20.0, 11.0, 20.0, 0.0),
								child:new Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: <Widget>[
										new Container(
											padding:const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
											child:new Text(name, 
												style:const TextStyle(
													fontSize:15.0,
													fontFamily:"Roboto",
													color: const Color.fromARGB(255, 48, 44, 72),
													decoration: TextDecoration.none)),
										),
										new Container(
											padding:const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 12.0),
											child:new Text(description, 
												style:const TextStyle(fontSize:12.0,color:Colors.grey, decoration: TextDecoration.none)),
										),
										new Row(
											children:<Widget>[
												new Expanded(child:new Text(rating.round().toString() + "/10", style:const TextStyle(fontSize:13.0,color:Colors.grey, decoration: TextDecoration.none))),
												new Expanded(child:new Text("\$"*min(dollarSigns,5), style:const TextStyle(fontSize:13.0,color:Colors.black, decoration: TextDecoration.none))),
												new Text(deliveryTime.toString() + " min", 
													style:const TextStyle(fontSize:13.0,color:Colors.grey, decoration: TextDecoration.none)),
											]
										)
									]
								)
							)
						)
					]
				)
			)
		);
	}
}

class RestaurantRow extends LeafRenderObjectWidget
{
	final String img;

	RestaurantRow(
		this.img,
		{
			Key key, 
		}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new RestaurantRowRenderer(
					img:img);
	}

	@override
	void updateRenderObject(BuildContext context, covariant RestaurantRowRenderer renderObject)
	{
		renderObject..img = img;
	}
}

class RestaurantRowRenderer extends RenderBox
{
	String _img;

	RestaurantRowRenderer(
		{
			String img
		})
	{
		this.img = img;
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
	}

	@override
	void paint(PaintingContext context, Offset offset)
	{
		final Canvas canvas = context.canvas;

		// final double width = size.width - Padding*2;
		canvas.save();
    	final RRect rrect = new RRect.fromRectAndRadius(offset & size, const Radius.circular(10.0));
		canvas.drawRRect(rrect, new ui.Paint()
			..color = Colors.white);
		canvas.restore();

		// // Draw bg & Flare
		// canvas.save();
		// canvas.translate(_scroll * size.width, 0.0);
		// canvas.drawRect(offset & new Size(size.width, size.height-DetailHeight/2.0), new ui.Paint()..color = _color);
		// canvas.restore();


		// // Draw Shadow
		// final double width = size.width - Padding*2;
		// canvas.save();
		// canvas.translate(_scroll * (width+ItemPadding), size.height-DetailHeight);
    	// final RRect rrect = new RRect.fromRectAndRadius(new Offset(offset.dx+Padding, offset.dy) & new Size(width, DetailHeight), const Radius.circular(10.0));
		// canvas.drawRRect(rrect.shift(const Offset(0.0, 20.0)), new ui.Paint()
		// 	..color = new Color.fromARGB(22, 0, 35, 120)
		// 	..maskFilter = _kShadowMaskFilter);
		// canvas.restore();
		
		// if(_actor != null)
		// {
		// 	canvas.save();
		// 	canvas.translate(_scroll * (width+ItemPadding), 0.0);
		// 	canvas.translate(size.width/2.0-_flareRect.left-_flareRect.width/2.0, (size.height-DetailHeight/2.0)/2.0-_flareRect.top-_flareRect.height/2.0);
		// 	_actor.draw(canvas);
		// 	canvas.restore();
		// }
		
		
	}


	String get img
	{
		return _img;
	}

	set img(String value)
	{
		if(_img == value)
		{
			return;
		}
		_img = value;
	}
}
