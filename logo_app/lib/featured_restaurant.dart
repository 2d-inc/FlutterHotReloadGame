import 'package:flutter/material.dart';

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