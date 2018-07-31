import 'package:flutter/material.dart';
import "dart:io";
import "monitor_widget.dart";

void main()
{
	runApp(new MonitorApp());
}

class MonitorApp extends StatelessWidget
{
	@override
	Widget build(BuildContext context)
	{
        ThemeData monitorData = ThemeData(platform: TargetPlatform.iOS);
		return new MaterialApp(
			home: new Monitor(),
            theme: monitorData
		);
	}
}