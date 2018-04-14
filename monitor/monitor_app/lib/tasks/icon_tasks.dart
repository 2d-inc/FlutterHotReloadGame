import "dart:math";
import "command_tasks.dart";

class AddIconATask extends CommandTask
{
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
		code = code.replaceAll("\"PIZZA_ICON\"", _hasPizza ? "\"assets/flares/PizzaIcon\"" : "null");
		code = code.replaceAll("\"BURGER_ICON\"", _hasBurger ? "\"assets/flares/BurgerIcon\"" : "null");
		code = code.replaceAll("\"DESSERT_ICON\"", _hasDessert ? "\"assets/flares/DessertIcon\"" : "null");
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

	bool doesAutoApply()
	{
		return true;
	}

	void tryToIssue(List<IssuedTask> currentQueue)
	{
		for(int i = 0; i < 10; i++)
		{
			Random rand = new Random();
			switch(rand.nextInt(3))
			{
				case 0:
					if(currentQueue.indexWhere((IssuedTask t) { return t.task is AddIconATask && t.value == 0; }) > -1)
					{
						continue;
					}
					currentQueue.add(new IssuedTask()..task = this
													..value = 0);
					return;
				case 1:
					if(currentQueue.indexWhere((IssuedTask t) { return t.task is AddIconATask && t.value == 1; }) > -1)
					{
						continue;
					}
					currentQueue.add(new IssuedTask()..task = this
													..value = 1);
					return;
				case 2:
					if(currentQueue.indexWhere((IssuedTask t) { return t.task is AddIconATask && t.value == 2; }) > -1)
					{
						continue;
					}
					currentQueue.add(new IssuedTask()..task = this
													..value = 2);
					return;
			}
		}
	}
}

class AddIconBTask extends CommandTask
{
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
		code = code.replaceAll("\"SUSHI_ICON\"", _hasSushi ? "\"assets/flares/SushiIcon\"" : "null");
		code = code.replaceAll("\"NOODLES_ICON\"", _hasNoodles ? "\"assets/flares/NoodlesIcon\"" : "null");
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

	bool doesAutoApply()
	{
		return true;
	}

	void tryToIssue(List<IssuedTask> currentQueue)
	{
		for(int i = 0; i < 10; i++)
		{
			Random rand = new Random();
			switch(rand.nextInt(2))
			{
				case 0:
					if(currentQueue.indexWhere((IssuedTask t) { return t.task is AddIconBTask && t.value == 0; }) > -1)
					{
						continue;
					}
					currentQueue.add(new IssuedTask()..task = this
													..value = 0);
					return;
				case 1:
					if(currentQueue.indexWhere((IssuedTask t) { return t.task is AddIconBTask && t.value == 1; }) > -1)
					{
						continue;
					}
					currentQueue.add(new IssuedTask()..task = this
													..value = 1);
					return;
			}
		}
	}
}