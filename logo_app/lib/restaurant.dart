import 'package:flutter/material.dart';
import "dart:math";

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