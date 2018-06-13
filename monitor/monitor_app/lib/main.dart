import 'package:flutter/material.dart';

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
		return new MaterialApp(
			home: new Monitor(),
		);
	}
}