import "dart:math";
import "command_tasks.dart";

class AddIconATask extends CommandTask
{
	List<String> options = ["PIZZA", "BURGER", "DESSERT"];
	
	bool _hasPizza = false;
	bool _hasBurger = false;
	bool _hasDessert = false;

	void complete(bool success, int value)
	{
		if(success)
		{
			switch(value)
			{
				case 0:
					_hasPizza = true;
					break;
				case 1:
					_hasBurger = true;
					break;
				case 2:
					_hasDessert = true;
					break;
			}
		}
	}

	String apply(String code)
	{
		code.replaceAll("\"PIZZA_ICON\"", _hasPizza ? "\"assets/flares/PizzaIcon\"" : "null");
		code.replaceAll("\"BURGER_ICON\"", _hasBurger ? "\"assets/flares/BurgerIcon\"" : "null");
		code.replaceAll("\"DESSERT_ICON\"", _hasDessert ? "\"assets/flares/DessertIcon\"" : "null");
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

	void complete(bool success, int value)
	{
		if(success)
		{
			switch(value)
			{
				case 0:
					_hasSushi = true;
					break;
				case 1:
					_hasNoodles = true;
					break;
			}
		}
	}

	String apply(String code)
	{
		code.replaceAll("\"SUSHI_ICON\"", _hasSushi ? "\"assets/flares/SushiIcon\"" : "null");
		code.replaceAll("\"NOODLES_ICON\"", _hasNoodles ? "\"assets/flares/NoodlesIcon\"" : "null");
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