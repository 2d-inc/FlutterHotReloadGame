import "dart:math";
import "command_tasks.dart";

class AddIconATask extends CommandTask
{
	@override
	bool isDelayed() { return true; }
	
	List<String> options = ["PIZZA", "BURGER", "DESSERT"];
	
	bool _hasPizza = false;
	bool _hasBurger = false;
	bool _hasDessert = false;
	
	Map serialize()
	{
		return CommandTask.makeBinary(this, options);
	}

	@override
	void prepareForFinal()
	{
		_hasPizza = true;
		_hasBurger = true;
		_hasDessert = true;
	}

	@override
	void setCurrentValue(int value)
    {
		if(value == -1)
		{
			_hasPizza = true;
			_hasBurger = true;
			_hasDessert = true;
		}
        super.setCurrentValue(value);
    }

	void complete(int value, String code)
	{
		switch(value)
		{
			case 0:
				_hasPizza = true;
				findLineOfInterest(code, "PIZZA_ICON");
				break;
			case 1:
				_hasBurger = true;
				findLineOfInterest(code, "BURGER_ICON");
				break;
			case 2:
				_hasDessert = true;
				findLineOfInterest(code, "DESSERT_ICON");
				break;
		}
	}

	String getIssueCommand(int value)
	{
		String name = options[value];
		return "ADD $name ICON!";
	}

	String apply(String code)
	{
		print("APPLYING ICON A $value");
		code = code.replaceAll("PIZZA_ICON", _hasPizza || !isPlayable ? "\"assets/flares/PizzaIcon\"" : "null");
		code = code.replaceAll("BURGER_ICON", _hasBurger || !isPlayable ? "\"assets/flares/BurgerIcon\"" : "null");
		code = code.replaceAll("DESSERT_ICON", _hasDessert || !isPlayable ? "\"assets/flares/DessertIcon\"" : "null");
		return code;
	}

	String taskType()
	{
		return "IconA";
	}

	String taskLabel()
	{
		return "Add Icon";
	}

	IssuedTask issue()
	{
		for(int i = 0; i < 10; i++)
		{
			Random rand = new Random();
			switch(rand.nextInt(3))
			{
				case 0:
					if(!_hasPizza)
					{
						return new IssuedTask()..task = this
												..value = 0;
					}
					break;
				case 1:
					if(!_hasBurger)
					{
						return new IssuedTask()..task = this
												..value = 1;
					}
					break;
				case 2:
					if(!_hasDessert)
					{
						return new IssuedTask()..task = this
												..value = 2;
					}
					break;
			}
		}

		return null;
	}
}

class AddIconBTask extends CommandTask
{
	@override
	bool isDelayed() { return true; }
	
	List<String> options = ["SUSHI", "NOODLES"];
	
	bool _hasSushi = false;
	bool _hasNoodles = false;

	Map serialize()
	{
		return CommandTask.makeBinary(this, options);
	}

	String getIssueCommand(int value)
	{
		String name = options[value];
		return "ADD $name ICON!";
	}

	@override
	void prepareForFinal()
	{
		_hasSushi = true;
		_hasNoodles = true;
	}

	@override
	void setCurrentValue(int value)
    {
		if(value == -1)
		{
			_hasSushi = true;
			_hasNoodles = true;
		}
        super.setCurrentValue(value);
    }

	void complete(int value, String code)
	{
		switch(value)
		{
			case 0:
				_hasSushi = true;
				findLineOfInterest(code, "SUSHI_ICON");
				break;
			case 1:
				_hasNoodles = true;
				findLineOfInterest(code, "NOODLES_ICON");
				break;
		}
		
	}

	String apply(String code)
	{
		code = code.replaceAll("SUSHI_ICON", _hasSushi || !isPlayable ? "\"assets/flares/SushiIcon\"" : "null");
		code = code.replaceAll("NOODLES_ICON", _hasNoodles || !isPlayable ? "\"assets/flares/NoodlesIcon\"" : "null");
		return code;
	}

	String taskType()
	{
		return "IconB";
	}

	String taskLabel()
	{
		return "Add Icon";
	}

	IssuedTask issue()
	{
		for(int i = 0; i < 10; i++)
		{
			Random rand = new Random();
			switch(rand.nextInt(2))
			{
				case 0:
					if(!_hasSushi)
					{
						return new IssuedTask()..task = this
												..value = 0;
					}
					break;
				case 1:
					if(!_hasNoodles)
					{
						return new IssuedTask()..task = this
												..value = 1;
					}
					break;
			}
		}
		return null;
	}
}


class SetBackgroundColor extends CommandTask
{
	List<String> options = ["WHITE", "GREY", "GREENISH"];
	List<String> colors = ["Colors.white", "Color.fromARGB(255, 242, 243, 246)", "Color.fromARGB(255, 200, 243, 200)"];
	
	SetBackgroundColor()
	{
		value = 0;
	}

	int get finalValue
	{
		return 1;
	}

	Map serialize()
	{
		return CommandTask.makeBinary(this, options);
	}

	void complete(int value, String code)
	{
		if(!hasLineOfInterest)
		{
			findLineOfInterest(code, "BACKGROUND_COLOR");
		}
	}

	String getIssueCommand(int value)
	{
		String name = options[value];
		return "SET BACKGROUND COLOR TO $name!";
	}

	String apply(String code)
	{
		return code.replaceAll("BACKGROUND_COLOR", colors[value]);
	}

	String taskType()
	{
		return "BackgroundColor";
	}

	String taskLabel()
	{
		return "Background Color";
	}

	IssuedTask issue()
	{
		Random rand = new Random();
		int v = value;
		while(v == value)
		{
			v = rand.nextInt(3);
		}

		return new IssuedTask()
								..task = this
								..value = v;
	}
}

class CarouselIcons extends CommandTask
{
	@override
	bool isDelayed() { return true; }
	
	List<String> options = ["HIDDEN", "STATIC", "ANIMATED"];
	List<String> values = ["IconType.hidden", "IconType.still", "IconType.animated"];
	
	int get finalValue
	{
		return 1;
	}

	Map serialize()
	{
		return CommandTask.makeBinary(this, options);
	}

	void complete(int value, String code)
	{
		if(!hasLineOfInterest)
		{
			findLineOfInterest(code, "CAROUSEL_ICON_TYPE");
		}
	}

	String getIssueCommand(int value)
	{
		String name = options[value];
		return "SET CAROUSEL ICONS TO $name!";
	}

	String apply(String code)
	{
		print("APPLYING CAROUSEL ICONS");
		return code.replaceAll("CAROUSEL_ICON_TYPE", values[value]);
	}

	String taskType()
	{
		return "CarouselIconType";
	}

	String taskLabel()
	{
		return "Set Carousel Icons";
	}

	IssuedTask issue()
	{
		Random rand = new Random();
		int v = value;
		while(v == value)
		{
			v = rand.nextInt(3);
		}

		return new IssuedTask()
								..task = this
								..value = v;
	}
}

class AddImages extends CommandTask
{
	// @override
	// bool isDelayed() { return true; }
	
	List<String> options = ["REMOVE IMAGES", "ADD IMAGES"];
	List<String> values = ["false", "true"];

	AddImages()
	{
		value = 1;
	}

	int get finalValue
	{
		return 1;
	}

	Map serialize()
	{
		return CommandTask.makeBinary(this, options);
	}

	void complete(int value, String code)
	{
		if(!hasLineOfInterest)
		{
			findLineOfInterest(code, "HAVE_IMAGES");
		}
	}

	String getIssueCommand(int value)
	{
		String name = options[value];
		return "$name!";
	}

	String apply(String code)
	{
		return code.replaceAll("HAVE_IMAGES", values[this.value]);
	}

	String taskType()
	{
		return "ShowImagesType";
	}

	String taskLabel()
	{
		return "Images";
	}

	IssuedTask issue()
	{
		int v = value == 1 ? 0 : 1;

		return new IssuedTask()
								..task = this
								..value = v;
	}
}

class ShowRatings extends CommandTask
{	
	ShowRatings()
	{
		value = 1;
	}

	int get finalValue
	{
		return 1;
	}
	
	List<String> options = ["HIDE RATINGS", "SHOW RATINGS"];
	List<String> values = ["false", "true"];
	Map serialize()
	{
		return CommandTask.makeBinary(this, options);
	}

	void complete(int value, String code)
	{
		if(!hasLineOfInterest)
		{
			findLineOfInterest(code, "SHOW_RATINGS");
		}
	}

	String getIssueCommand(int value)
	{
		String name = options[value];
		return "$name!";
	}

	String apply(String code)
	{
		return code.replaceAll("SHOW_RATINGS", values[this.value]);
	}

	String taskType()
	{
		return "ShowRatingsType";
	}

	String taskLabel()
	{
		return "Ratings";
	}

	IssuedTask issue()
	{
		int v = value == 1 ? 0 : 1;

		return new IssuedTask()
								..task = this
								..value = v;
	}
}

class ShowDeliveryTimes extends CommandTask
{	
	ShowDeliveryTimes()
	{
		value = 1;
	}

	int get finalValue
	{
		return 1;
	}
	
	List<String> options = ["HIDE DELIVERY TIMES", "SHOW DELIVERY TIMES"];
	List<String> values = ["false", "true"];
	Map serialize()
	{
		return CommandTask.makeBinary(this, options);
	}

	void complete(int value, String code)
	{
		if(!hasLineOfInterest)
		{
			findLineOfInterest(code, "SHOW_DELIVERY_TIMES");
		}
	}

	String getIssueCommand(int value)
	{
		String name = options[value];
		return "$name!";
	}

	String apply(String code)
	{
		return code.replaceAll("SHOW_DELIVERY_TIMES", values[this.value]);
	}

	String taskType()
	{
		return "ShowDeliveryTimesType";
	}

	String taskLabel()
	{
		return "Delivery Times";
	}

	IssuedTask issue()
	{
		int v = value == 1 ? 0 : 1;

		return new IssuedTask()
								..task = this
								..value = v;
	}
}

class CondenseListItems extends CommandTask
{	
	CondenseListItems()
	{
		value = 0;
	}

	int get finalValue
	{
		return 0;
	}
	
	List<String> options = ["EXPANDED", "CONDENSED"];
	List<String> values = ["false", "true"];
	Map serialize()
	{
		return CommandTask.makeBinary(this, options);
	}

	void complete(int value, String code)
	{
		if(!hasLineOfInterest)
		{
			findLineOfInterest(code, "CONDENSE_LIST_ITEMS");
		}
	}

	String getIssueCommand(int value)
	{
		return value == 0 ? "EXPAND LIST ITEMS!" : "CONDENSE LIST ITEMS!";
	}

	String apply(String code)
	{
		return code.replaceAll("CONDENSE_LIST_ITEMS", values[this.value]);
	}

	String taskType()
	{
		return "CondenseListItemsType";
	}

	String taskLabel()
	{
		return "List Item Size";
	}

	IssuedTask issue()
	{
		int v = value == 1 ? 0 : 1;

		return new IssuedTask()
								..task = this
								..value = v;
	}
}

class CategoryFontWeight extends CommandTask
{	
	CategoryFontWeight()
	{
		value = 0;
	}

	int get finalValue
	{
		return 0;
	}
	
	List<String> options = ["NORMAL", "BOLD"];
	List<String> values = ["FontWeight.normal", "FontWeight.w700"];
	Map serialize()
	{
		return CommandTask.makeBinary(this, options);
	}

	void complete(int value, String code)
	{
		if(!hasLineOfInterest)
		{
			findLineOfInterest(code, "CATEGORY_FONT_WEIGHT");
		}
	}

	String getIssueCommand(int value)
	{
		return "SET CATEGORY FONT WEIGHT TO ${options[value]}!";
	}

	String apply(String code)
	{
		return code.replaceAll("CATEGORY_FONT_WEIGHT", values[this.value]);
	}

	String taskType()
	{
		return "CategoryFontWeightType";
	}

	String taskLabel()
	{
		return "Category Font Weight";
	}

	IssuedTask issue()
	{
		int v = value == 1 ? 0 : 1;

		return new IssuedTask()
								..task = this
								..value = v;
	}
}

class FontFamily extends CommandTask
{	
	List<String> options = ["DEFAULT", "ROBOTO", "INCONSOLATA"];
	List<String> values = ["null", "'Roboto'", "'Inconsolata'"];

	int get finalValue
	{
		return 1;
	}

	Map serialize()
	{
		return CommandTask.makeBinary(this, options);
	}

	void complete(int value, String code)
	{
		if(!hasLineOfInterest)
		{
			findLineOfInterest(code, "FONT_FAMILY");
		}
	}

	String getIssueCommand(int value)
	{
		String name = options[value];
		return "SET FONT FAMILY TO $name!";
	}

	String apply(String code)
	{
		print("APPLYING FONT FAMILY $value");
		return code.replaceAll("FONT_FAMILY", values[value]);
	}

	String taskType()
	{
		return "FontFamilyType";
	}

	String taskLabel()
	{
		return "Set Font Family";
	}

	IssuedTask issue()
	{
		Random rand = new Random();
		int v = value;
		while(v == value)
		{
			v = rand.nextInt(3);
		}

		return new IssuedTask()
								..task = this
								..value = v;
	}
}
