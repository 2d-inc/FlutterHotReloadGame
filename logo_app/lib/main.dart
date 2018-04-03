import 'package:flutter/material.dart';
import "featured_restaurant.dart";
import "category.dart";
import "restaurant.dart";

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
	// This widget is the root of your application.
	@override
	Widget build(BuildContext context) {
		return new MaterialApp(
			title: 'Flutter Demo',
			theme: new ThemeData(
				// This is the theme of your application.
				//
				// Try running your application with "flutter run". You'll see the
				// application has a blue toolbar. Then, without quitting the app, try
				// changing the primarySwatch below to Colors.green and then invoke
				// "hot reload" (press "r" in the console where you ran "flutter run",
				// or press Run > Flutter Hot Reload in IntelliJ). Notice that the
				// counter didn't reset back to zero; the application is not restarted.
				primarySwatch: Colors.blue,
			),
			home: new MyHomePage(title: 'Flutter Demo Home Page'),
		);
	}
}


List<FeaturedRestaurantData> featuredRestaurants = <FeaturedRestaurantData>[
	const FeaturedRestaurantData("Pizzeria Delfina", description: "This energetic, farm-to-table restaurant serves up Neopolitan-inspired pizza with gelato.", deliveryTime: 15, color:const Color.fromARGB(255, 255, 223, 204), flare:"assets/flares/Pizza"),
	const FeaturedRestaurantData("Bushido Izakaya", description: "Impeccable Japanese flavors with a contemporary flair.", deliveryTime: 32, color:const Color.fromARGB(255, 237, 218, 229)),
	const FeaturedRestaurantData("Umami Burger", description: "Serves gourmet burgers, truffle fries, salads, and craft beers for lunch and dinner.", deliveryTime: 27, color:const Color.fromARGB(255, 255, 234, 216)),
];

class MyHomePage extends StatefulWidget {
	MyHomePage({Key key, this.title}) : super(key: key);

	// This widget is the home page of your application. It is stateful, meaning
	// that it has a State object (defined below) that contains fields that affect
	// how it looks.

	// This class is the configuration for the state. It holds the values (in this
	// case the title) provided by the parent (in this case the App widget) and
	// used by the build method of the State. Fields in a Widget subclass are
	// always marked "final".

	final String title;

	@override
	_MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
	// int _counter = 0;

	// void _incrementCounter() {
	// 	setState(() {
	// 		// This call to setState tells the Flutter framework that something has
	// 		// changed in this State, which causes it to rerun the build method below
	// 		// so that the display can reflect the updated values. If we changed
	// 		// _counter without calling setState(), then the build method would not be
	// 		// called again, and so nothing would appear to happen.
	// 		_counter++;
	// 	});
	// }

	@override
	Widget build(BuildContext context) {
		return new Container(
			decoration:new BoxDecoration(
				color: true ? new Color.fromARGB(255, 242, 243, 246) : Colors.white),
			child:new ListView(
				shrinkWrap: true,
				padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
				children: <Widget>[
					new Container(
						height:305.0,
						child:new FeaturedCarousel(data:featuredRestaurants),
					),
					/*new Container(
						padding:const EdgeInsets.fromLTRB(20.0, 5.0, 0.0, 10.0),
						child:new Text("Featured", 
							style:const TextStyle(fontSize:13.0,color:Colors.black, decoration: TextDecoration.none)),
					),
					new Container(
						height:210.0,
						child:new ListView(
							shrinkWrap: true,
							padding:const EdgeInsets.fromLTRB(20.0, 0.0, 0.0, 0.0),
							scrollDirection: Axis.horizontal,
							children: <Widget> [
								const FeaturedRestaurantSimple('Pizzeria Delfina', description: "This energetic, farmers-to-table restaurant serves up Neopolitan-inspired pizza and gelato.", deliveryTime:15),
								const FeaturedRestaurantSimple('Bushido Izakaya', description: "Impeccable Japanese flavors with a contemporary flair.", deliveryTime:32),
								const FeaturedRestaurantSimple('Umami Burgers', description: "Umami Burgers serves burgers, fries...", deliveryTime:45)
							]
						)
					),*/
					new Container(
						height:133.0,
						child:new ListView(
							shrinkWrap: true,
							padding:const EdgeInsets.fromLTRB(20.0, 0.0, 0.0, 0.0),
							scrollDirection: Axis.horizontal,
							children: <Widget> [
								const CategoryDesigned('Pizza'),
								const CategoryDesigned('Burgers'),
								const CategoryDesigned('Dessert'),
								const CategoryDesigned('Sushi'),
								const CategoryDesigned('Chinese'),
							]
						)
					),
					new RestaurantsHeaderDesigned(),
					/*const RestaurantSimple('Curry Up Now', description:"Indian Street Food", deliveryTime: 29, rating: 9, dollarSigns: 2),
					const RestaurantSimple('Sprout Cafe', description:"Salads", deliveryTime: 29, rating: 9, dollarSigns: 2),
					const RestaurantSimple('Asian Box', description:"Fresh Sustainable Asian Street Food", deliveryTime: 29, rating: 9, dollarSigns: 2),
					const RestaurantSimple('pokeLove', description:"Hawaiian", deliveryTime: 29, rating: 9, dollarSigns: 2),*/
					const RestaurantDesigned('Curry Up Now', description:"Indian Street Food", deliveryTime: 29, rating: 9, dollarSigns: 2, img:"assets/images/samosa.jpg"),
					const RestaurantDesigned('Sprout Cafe', description:"Salads", deliveryTime: 29, rating: 9, dollarSigns: 2, img:"assets/images/cafe.jpg"),
					const RestaurantDesigned('Asian Box', description:"Fresh Sustainable Asian Street Food", deliveryTime: 29, rating: 9, dollarSigns: 2, img:"assets/images/pizza.jpg"),
					const RestaurantDesigned('pokeLove', description:"Hawaiian", deliveryTime: 29, rating: 9, dollarSigns: 2, img:"assets/images/poke.jpg"),
				],
			)
		);
	}
}