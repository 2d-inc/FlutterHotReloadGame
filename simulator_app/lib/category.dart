import 'package:flutter/material.dart';
import "flare_widget.dart";

const FontWeight CATEGORY_FONT_WEIGHT = FontWeight.normal;

class CategorySimple extends StatelessWidget
{
	const CategorySimple(this.name, 
	{
		Key key,
		this.flare,
		this.fontSize,
		this.fontWeight,
		this.fontFamily
	}) : assert(name != null),
			super(key: key);

	final String name;
	final String flare;
	final double fontSize;
	final FontWeight fontWeight;
	final String fontFamily;

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
							style:new TextStyle(fontFamily:fontFamily, fontSize:fontSize,color:Colors.black, decoration: TextDecoration.none, fontWeight: fontWeight))
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
		Key key,
		this.flare,
		this.fontSize,
		this.fontWeight,
		this.fontFamily
	}) : assert(name != null),
			super(key: key);

	final String name;
	final String flare;
	final double fontSize;
	final FontWeight fontWeight;
	final String fontFamily;

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
							style:new TextStyle(fontFamily:fontFamily, fontSize:fontSize,color:Colors.grey, decoration: TextDecoration.none, fontWeight: fontWeight))
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
		this.flare,
		this.fontSize,
		this.fontWeight,
		this.fontFamily
	}) : assert(name != null),
			super(key: key);

	final String name;
	final String flare;
	final double fontSize;
	final FontWeight fontWeight;
	final String fontFamily;

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
							style:new TextStyle(fontSize:fontSize, fontFamily:fontFamily, color:const Color.fromARGB(255, 158, 164, 184), decoration: TextDecoration.none, fontWeight: fontWeight))
					)
				]
			)
		);
	}
}
