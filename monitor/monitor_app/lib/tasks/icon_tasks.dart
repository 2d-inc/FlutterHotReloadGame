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
		code = code.replaceAll("PIZZA_ICON", _hasPizza ? "\"assets/flares/PizzaIcon\"" : "null");
		code = code.replaceAll("BURGER_ICON", _hasBurger ? "\"assets/flares/BurgerIcon\"" : "null");
		code = code.replaceAll("DESSERT_ICON", _hasDessert ? "\"assets/flares/DessertIcon\"" : "null");
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
		code = code.replaceAll("SUSHI_ICON", _hasSushi ? "\"assets/flares/SushiIcon\"" : "null");
		code = code.replaceAll("NOODLES_ICON", _hasNoodles ? "\"assets/flares/NoodlesIcon\"" : "null");
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
	int _colorIdx = 0;
	Map serialize()
	{
		return CommandTask.makeBinary(this, options);
	}

	void complete(int value, String code)
	{
		_colorIdx = value;
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
		return code.replaceAll("BACKGROUND_COLOR", colors[_colorIdx]);
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
	int _valueIdx = 0;
	Map serialize()
	{
		return CommandTask.makeBinary(this, options);
	}

	void complete(int value, String code)
	{
		_valueIdx = value;
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
		return code.replaceAll("CAROUSEL_ICON_TYPE", values[_valueIdx]);
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