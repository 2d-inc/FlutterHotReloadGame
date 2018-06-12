import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import "code_box_widget.dart";

void main()
{
	runApp(new MonitorApp());
}

class MonitorApp extends StatelessWidget
{
	@override
	Widget build(BuildContext context)
	{
		return new MaterialApp(
			home: new CodeBox(),
		);
	}
}

Future<String> loadFileAssets(String filename) async
{
	return await rootBundle.loadString("assets/files/$filename");
}