import 'package:flutter/material.dart';
import "flare_widget.dart";

class CategorySimple extends StatelessWidget
{
	const CategorySimple(this.name, 
	{
		Key key
	}) : assert(name != null),
			super(key: key);

	final String name;

	Widget build(BuildContext context) 
	{
		return new Container(
			padding:const EdgeInsets.fromLTRB(0.0, 0.0, 10.0, 0.0),
			child: new Column(
				crossAxisAlignment: CrossAxisAlignment.center,
				children: <Widget>[
					new SizedBox(
						width:80.0, 
						height:80.0, 
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
						padding:new EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
						child:new Text("Category", 
							style:const TextStyle(fontSize:11.0,color:Colors.black, decoration: TextDecoration.none))
					)
				]
			)
		);
	}
}

class CategoryAligned extends StatelessWidget
{
	const CategoryAligned(this.name, 
	{
		Key key
	}) : assert(name != null),
			super(key: key);

	final String name;

	Widget build(BuildContext context) 
	{
		return new Container(
			padding:const EdgeInsets.fromLTRB(0.0, 0.0, 10.0, 0.0),
			child: new Column(
				crossAxisAlignment: CrossAxisAlignment.center,
				children: <Widget>[
					new SizedBox(
						width:80.0, 
						height:80.0, 
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
						padding:new EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
						child:new Text(name, 
							style:const TextStyle(fontSize:12.0,color:Colors.grey, decoration: TextDecoration.none))
					)
				]
			)
		);
	}
}

class CategoryDesigned extends StatelessWidget
{
	const CategoryDesigned(this.name, 
	{
		Key key,
		this.flare
	}) : assert(name != null),
			super(key: key);

	final String name;
	final String flare;

	Widget build(BuildContext context) 
	{
		return new Container(
			padding:const EdgeInsets.fromLTRB(0.0, 24.0, 20.0, 0.0),
			child: new Column(
				crossAxisAlignment: CrossAxisAlignment.center,
				children: <Widget>[
					new Container(
						width:64.0, 
						height:64.0, 
						decoration:new BoxDecoration(
							color: const Color.fromARGB(25, 158, 164, 184), 
							borderRadius: const BorderRadius.all(const Radius.circular(32.0))
						),
						child:new Container( alignment: Alignment.center, child:flare != null ? new Flare(flare) : null)
					),
					new Container(
						padding:new EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
						child:new Text(name, 
							style:const TextStyle(fontSize:15.0, fontFamily:"Roboto", color:const Color.fromARGB(255, 158, 164, 184), decoration: TextDecoration.none))
					)
				]
			)
		);
	}
}
