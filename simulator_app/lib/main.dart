import 'package:flutter/material.dart';
import "featured_restaurant.dart";
import "category.dart";
import "restaurant.dart";
import "flare_widget.dart";

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
	// This widget is the root of your application.
	@override
	Widget build(BuildContext context) {
		return new MaterialApp(
			title: 'Flutter Demo',
			debugShowCheckedModeBanner: false,
			theme: new ThemeData(
			),
			home: new MyHomePage(title: 'Flutter Demo Home Page'),
		);
	}
}


List<FeaturedRestaurantData> featuredRestaurants = <FeaturedRestaurantData>[
	const FeaturedRestaurantData("Pizza Place", description: "This energetic, farm-to-table restaurant serves up Neopolitan-inspired pizza with gelato.", deliveryTime: 15, color:const Color.fromARGB(255, 255, 223, 204), flare:"assets/flares/Pizzeria"),
	const FeaturedRestaurantData("Sushi Overload", description: "Impeccable Japanese flavors with a contemporary flair.", deliveryTime: 32, color:const Color.fromARGB(255, 237, 218, 229), flare:"assets/flares/Sushi"),
	const FeaturedRestaurantData("Burger Paradise", description: "Serves gourmet burgers, truffle fries, salads, and craft beers for lunch and dinner.", deliveryTime: 27, color:const Color.fromARGB(255, 255, 234, 216), flare:"assets/flares/Pizzeria"),
];

class MyHomePage extends StatefulWidget {
	MyHomePage({Key key, this.title}) : super(key: key);

	final String title;

	@override
	_MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
	@override
	Widget build(BuildContext context) {

		const double featuredRestaurantSize = FEATURED_RESTAURANT_SIZE;
		
		return new Container(
			decoration:new BoxDecoration(color: Colors.white),
			child:
			new Stack(
				children:<Widget>[
				new ListView(
				shrinkWrap: true,
				padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
				children: <Widget>[
					featuredRestaurantSize > 10 ? new Container(
						height:featuredRestaurantSize,
						child:new FeaturedCarousel(data:featuredRestaurants, 
													fontFamily: 'Roboto', 
													cornerRadius: 5.0, 
													iconType:IconType.animated, 
													fontSize:12.0),
					) : 
					new Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: <Widget>
						[
							new Container(
								padding:const EdgeInsets.fromLTRB(20.0, 15.0, 0.0, 10.0),
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
										const FeaturedRestaurantAligned('Pizza Place', description: "This energetic, farmers-to-table restaurant serves up Neopolitan-inspired pizza and gelato.", deliveryTime:15, cornerRadius:5.0, fontSize:12.0, fontFamily: 'Roboto'),
										const FeaturedRestaurantAligned('Sushi Overload', description: "Impeccable Japanese flavors with a contemporary flair.", deliveryTime:32, cornerRadius:5.0, fontSize:12.0, fontFamily: 'Roboto'),
										const FeaturedRestaurantAligned('Burger Paradise', description: "Umami Burgers serves burgers, fries...", deliveryTime:45, cornerRadius:5.0, fontSize:12.0, fontFamily: 'Roboto')
									]
								)
							)
						]
					),
					new Container(
						height:133.0,
						child:new ListView(
							shrinkWrap: true,
							padding:const EdgeInsets.fromLTRB(20.0, 0.0, 0.0, 0.0),
							scrollDirection: Axis.horizontal,
							children: <Widget> [
								const CategoryAligned('Pizza', 
														flare:"assets/flares/PizzaIcon", 
														fontSize:12.0, 
														fontWeight:FontWeight.w700, 
														fontFamily: 'Roboto'),
								const CategoryAligned('Burgers', 
														flare:"assets/flares/BurgerIcon", 
														fontSize:12.0, 
														fontWeight:FontWeight.w700, 
														fontFamily: 'Roboto'),
								const CategoryAligned('Dessert', 
														flare:"assets/flares/DessertIcon", 
														fontSize:12.0, 
														fontWeight:FontWeight.w700, 
														fontFamily: 'Roboto'),
								const CategoryAligned('Sushi', 
														flare:null, 
														fontSize:12.0, 
														fontWeight:FontWeight.w700, 
														fontFamily: 'Roboto'),
								const CategoryAligned('Chinese', 
														flare:null, 
														fontSize:12.0, 
														fontWeight:FontWeight.w700, 
														fontFamily: 'Roboto'),
							]
						)
					),
					new RestaurantsHeaderAligned(fontFamily: 'Roboto'),
					const ListRestaurantSimple('Indian Food', 
												cornerRadius:10.0, 
												description:"Indian Street Food", 
												deliveryTime: 29, 
												rating: 9, 
												dollarSigns: 2, 
												img:"assets/images/samosa.jpg", 
												padding:20.0, 
												showImage:true, 
												showRating:true, 
												showDeliveryTime: true, 
												totalDollarSigns:3, 
												isCondensed:false, 
												imageWidth:108, 
												fontFamily: 'Roboto'),
					const ListRestaurantSimple('Fancy Cafe', cornerRadius:10.0, description:"Salads", deliveryTime: 29, rating: 9, dollarSigns: 2, img:"assets/images/cafe.jpg", padding:20.0, showImage:true, showRating:true, showDeliveryTime: true, totalDollarSigns:3, isCondensed:false, imageWidth:108, fontFamily: 'Roboto'),
					const ListRestaurantSimple('Asian Fare', cornerRadius:10.0, description:"Fresh Sustainable Asian Street Food", deliveryTime: 29, rating: 9, dollarSigns: 2, img:"assets/images/pizza.jpg", padding:20.0, showImage:true, showRating:true, showDeliveryTime: true, totalDollarSigns:3, isCondensed:false, imageWidth:108, fontFamily: 'Roboto'),
					const ListRestaurantSimple('Fresh from Hawaii', cornerRadius:10.0, description:"Hawaiian", deliveryTime: 29, rating: 9, dollarSigns: 2, img:"assets/images/poke.jpg", padding:20.0, showImage:true, showRating:true, showDeliveryTime: true, totalDollarSigns:3, isCondensed:false, imageWidth:108, fontFamily: 'Roboto'),
					const ListRestaurantSimple('Indian Food', cornerRadius:10.0, description:"Indian Street Food", deliveryTime: 29, rating: 9, dollarSigns: 2, img:"assets/images/samosa.jpg", padding:20.0, showImage:true, showRating:true, showDeliveryTime: true, totalDollarSigns:3, isCondensed:false, imageWidth:108, fontFamily: 'Roboto'),
				],
			),
			new Container(padding:const EdgeInsets.fromLTRB(20.0, 30.0, 0.0, 0.0), alignment: Alignment.topLeft, child:new Flare("assets/flares/MenuIcon")),
			new Container(padding:const EdgeInsets.fromLTRB(0.0, 30.0, 20.0, 0.0), alignment: Alignment.topRight, child:new Flare("assets/flares/SearchIcon"))
			])
		);
	}
}