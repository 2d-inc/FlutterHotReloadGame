import 'package:flutter/material.dart';

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
