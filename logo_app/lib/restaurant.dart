import 'package:flutter/material.dart';
import "dart:math";
import "dart:ui" as ui;

const double LIST_CORNER_RADIUS = 0.0;
const bool SHOW_RATINGS = true;
const bool HAVE_IMAGES = true;
const bool SHOW_DELIVERY_TIMES = true;
const int DOLLAR_SIGNS = 4;
const bool CONDENSE_LIST_ITEMS = false;

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

class RestaurantsHeaderDesigned extends StatelessWidget
{
	Widget build(BuildContext context)
	{
		return new Container(
			padding:const EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 17.0),
			child:new Row(
				children: <Widget>[
					new Expanded(child:new Text("NEARBY", style:const TextStyle(fontSize:14.0, fontWeight: FontWeight.w500, fontFamily: "Roboto", color:const Color.fromARGB(127, 48, 44, 72), decoration: TextDecoration.none))),
					new Text("1600 Amphitheater Pkwy", style:const TextStyle(fontSize:15.0, fontFamily: "Roboto", color:const Color.fromARGB(255, 107, 146, 242), decoration: TextDecoration.none, fontWeight: FontWeight.normal)),
				]
			)
		);
	}
}

class ListRestaurantSimple extends StatelessWidget
{
	const ListRestaurantSimple(this.name, 
	{
		Key key,
		this.description,
		this.dollarSigns,
		this.deliveryTime,
		this.rating,
		this.img,
		this.showImage,
		this.showRating,
		this.showDeliveryTime,
		this.totalDollarSigns,
		this.cornerRadius,
		this.padding,
		this.isCondensed
	}) : assert(name != null),
			super(key: key);
	
	final String name;
	final String description;
	final int dollarSigns;
	final int deliveryTime;
	final int rating;
	final String img;
	final bool showImage;
	final bool showRating;
	final bool showDeliveryTime;
	final int totalDollarSigns;
	final double cornerRadius;
	final double padding;
	final bool isCondensed;
	
	Widget build(BuildContext context) 
	{
		return new Container(
			padding:new EdgeInsets.fromLTRB(padding, 0.0, 0.0, isCondensed ? 5.0 : 10.0),
			child: new Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: <Widget>[
					showImage ? new SizedBox(
						width:100.0, 
						height:isCondensed ? 70.0 : 100.0, 
						child:new Container(
							decoration:new BoxDecoration(
								border: new Border.all(
									color: Colors.black,
									width: 1.0,
								),
								borderRadius: new BorderRadius.circular(cornerRadius)
							)
						)
					) : new Container(),
					new Container(
						padding:new EdgeInsets.fromLTRB(0.0, isCondensed ? 0.0 : 5.0, 0.0, 0.0),
						child:new Text("Restaurant Name", 
							style:new TextStyle(fontSize:isCondensed ? 8.0 : 10.0, color:Colors.black, decoration: TextDecoration.none)),
					),
					new Text("Description", 
						style:new TextStyle(fontSize:isCondensed ? 8.0 : 10.0,color:Colors.black, decoration: TextDecoration.none)),
					showRating ? new Text("0/10", 
						style:new TextStyle(fontSize:isCondensed ? 8.0 : 10.0, color:Colors.black, decoration: TextDecoration.none)) : new Container(),
					new Text("\$"*totalDollarSigns, 
						style:new TextStyle(fontSize:isCondensed ? 8.0 : 10.0, color:Colors.black, decoration: TextDecoration.none)),
					showDeliveryTime ? new Text("0 min", 
						style:new TextStyle(fontSize:isCondensed ? 8.0 : 10.0, color:Colors.black, decoration: TextDecoration.none)) : new Container(),
				]
			)
		);
	}
}

class ListRestaurantAligned extends StatelessWidget
{
	const ListRestaurantAligned(this.name, 
	{
		Key key,
		this.description,
		this.dollarSigns,
		this.deliveryTime,
		this.rating,
		this.img,
		this.showImage,
		this.showRating,
		this.showDeliveryTime,
		this.totalDollarSigns,
		this.cornerRadius,
		this.padding,
		this.isCondensed
	}) : assert(name != null),
			super(key: key);
	
	final String name;
	final String description;
	final String img;
	final bool showImage;
	final bool showRating;
	final bool showDeliveryTime;
	final int dollarSigns;
	final int deliveryTime;
	final int rating;
	final int totalDollarSigns;
	final double cornerRadius;
	final double padding;
	final bool isCondensed;

	Widget build(BuildContext context) 
	{
		return new Container(
			padding:new EdgeInsets.fromLTRB(padding, 0.0, 0.0, isCondensed ? 5.0 : 10.0),
			child: new Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: <Widget>[
					showImage ? new SizedBox(
						width:100.0, 
						height:isCondensed ? 70.0 : 100.0, 
						child:new Container(
							decoration:new BoxDecoration(
								border: new Border.all(
									color: Colors.black,
									width: 1.0,
								),
								borderRadius: new BorderRadius.circular(cornerRadius)
							)
						)
					) : new Container(),
					new Expanded(
						child:new Container(
							padding: new EdgeInsets.fromLTRB(20.0, 0.0, isCondensed ? 10.0 : 20.0, 0.0),
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
											showRating ? new Expanded(child:new Text(rating.round().toString() + "/10", style:const TextStyle(fontSize:13.0,color:Colors.grey, decoration: TextDecoration.none))) : new Container(),
											new Expanded(
													child:new Row(
            											mainAxisSize: MainAxisSize.min,
														children: [
															new Text("\$"*min((dollarSigns/5.0*totalDollarSigns).round(),totalDollarSigns), style:const TextStyle(fontSize:13.0, color:const Color.fromARGB(255, 48, 44, 72), decoration: TextDecoration.none, fontWeight: FontWeight.normal)),
															new Text("\$"*(totalDollarSigns-min((dollarSigns/5.0*totalDollarSigns).round(),totalDollarSigns)), style:const TextStyle(fontSize:13.0, color:const Color.fromARGB(102, 48, 44, 72), decoration: TextDecoration.none, fontWeight: FontWeight.normal))
														]
													)
												),
											showDeliveryTime ? new Text(deliveryTime.toString() + " min", 
												style:const TextStyle(fontSize:13.0,color:Colors.grey, decoration: TextDecoration.none)) : new Container(),
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

class ListRestaurantDesigned extends StatelessWidget
{
	const ListRestaurantDesigned(this.name, 
	{
		Key key,
		this.description,
		this.dollarSigns,
		this.totalDollarSigns,
		this.deliveryTime,
		this.rating,
		this.img,
		this.showImage,
		this.showRating,
		this.showDeliveryTime,
		this.cornerRadius = 10.0,
		this.padding,
		this.isCondensed
	}) : assert(name != null),
			super(key: key);
	
	final String name;
	final String description;
	final String img;
	final bool showImage;
	final bool showRating;
	final bool showDeliveryTime;
	final int dollarSigns;
	final int totalDollarSigns;
	final int deliveryTime;
	final int rating;
	final double cornerRadius;
	final double padding;
	final bool isCondensed;
	
	Widget build(BuildContext context) 
	{
		return new Container(
			padding:new EdgeInsets.fromLTRB(padding, 0.0, isCondensed ? 10.0 : 20.0, isCondensed ? 10.0 : 20.0),
			child:new Container(
				decoration: new BoxDecoration(
					color:Colors.white, 
					borderRadius: new BorderRadius.all(new Radius.circular(this.cornerRadius)),
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
						showImage ? new Container(
							width:100.0,
							height:isCondensed ? 70.0 : 100.0,
							decoration: new BoxDecoration(
								borderRadius: new BorderRadius.only(topLeft:new Radius.circular(this.cornerRadius), bottomLeft:new Radius.circular(this.cornerRadius)),
								
								image: new DecorationImage(
									image: new ExactAssetImage(img),
									fit: BoxFit.cover,
									alignment: Alignment.center
									
								),
							)
						) : new Container(),
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
													fontWeight: FontWeight.normal,
													decoration: TextDecoration.none)),
										),
										new Container(
											padding:const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 16.0),
											child:new Text(description, 
												maxLines: 1,
												overflow: TextOverflow.ellipsis,
												style:const TextStyle(
													fontSize:15.0,
													fontFamily:"Roboto",
													color: const Color.fromARGB(102, 48, 44, 72),
													fontWeight: FontWeight.normal,
													decoration: TextDecoration.none)
												),
										),
										new Row(
											children:<Widget>[
												showRating ? new Expanded(child:new Text(rating.round().toString() + "/10", style:const TextStyle(fontSize:15.0, fontFamily: "Roboto", color:const Color.fromARGB(102, 48, 44, 72), fontWeight: FontWeight.normal, decoration: TextDecoration.none))) : new Container(),
												new Expanded(
													child:new Row(
            											mainAxisSize: MainAxisSize.min,
														children: [
															new Text("\$"*min((dollarSigns/5.0*totalDollarSigns).round(),totalDollarSigns), style:const TextStyle(fontSize:15.0, fontFamily:"Roboto", color:const Color.fromARGB(255, 48, 44, 72), decoration: TextDecoration.none, fontWeight: FontWeight.normal)),
															new Text("\$"*(totalDollarSigns-min((dollarSigns/5.0*totalDollarSigns).round(),totalDollarSigns)), style:const TextStyle(fontSize:15.0, fontFamily:"Roboto", color:const Color.fromARGB(102, 48, 44, 72), decoration: TextDecoration.none, fontWeight: FontWeight.normal))
														]
													)
												),
												showDeliveryTime ? new Text(deliveryTime.toString() + " min", 
													style:const TextStyle(fontSize:15.0, fontFamily: "Roboto", color:const Color.fromARGB(102, 48, 44, 72), decoration: TextDecoration.none, fontWeight: FontWeight.normal)) : new Container(),
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
