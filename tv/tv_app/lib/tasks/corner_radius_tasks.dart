import "dart:math";

import "command_tasks.dart";

class ListCornerRadius extends CommandTask
{	
	ListCornerRadius()
	{
		value = 10;
	}

	Map serialize()
	{
		return CommandTask.makeRadial(this, 10, 30);
	}

	void complete(int value, String code)
	{
		if(!hasLineOfInterest)
		{
			findLineOfInterest(code, "LIST_CORNER_RADIUS");
		}
	}

	String getIssueCommand(int value)
	{
		return "SET LIST RADIUS TO $value";
	}
	
	String apply(String code)
	{
		code = code.replaceAll("LIST_CORNER_RADIUS", value.toString() + ".0");
		return code;
	}

	String taskType()
	{
		return "ListRadius";
	}

	String taskLabel()
	{
		return "Set List Radius";
	}

	int get finalValue
	{
		return 10;
	}

	IssuedTask issue()
	{
		Random rand = new Random();
		int v = value;
		while(v == value)
		{
			switch(rand.nextInt(5))
			{	
				case 0:
					v = 10;
					break;
				case 1:
					v = 15;
					break;
				case 2:
					v = 20;
					break;
				case 3:
					v = 25;
					break;
				case 4:
					v = 30;
					break;
			}
		}
		return new IssuedTask()
								..task = this
								..value = v;
	}
}

class FeaturedCornerRadius extends CommandTask
{
	FeaturedCornerRadius()
	{
		value = 5;
	}

	Map serialize()
	{
		return CommandTask.makeRadial(this, 5, 25);
	}

	void complete(int value, String code)
	{
		if(!hasLineOfInterest)
		{
			findLineOfInterest(code, "FEATURED_CORNER_RADIUS");
		}
	}
	
	String getIssueCommand(int value)
	{
		return "SET FEATURED RADIUS TO $value";
	}

	String apply(String code)
	{
		code = code.replaceAll("FEATURED_CORNER_RADIUS", value.toString() + ".0");
		return code;
	}

	String taskType()
	{
		return "FeaturedRadius";
	}

	String taskLabel()
	{
		return "Set Featured Radius";
	}

	int get finalValue
	{
		return 10;
	}

	IssuedTask issue()
	{
		Random rand = new Random();
		int v = value;
		while(v == value)
		{
			switch(rand.nextInt(5))
			{
				case 0:
					v = 5;
					break;
				case 1:
					v = 10;
					break;
				case 2:
					v = 15;
					break;
				case 3:
					v = 20;
					break;
				case 4:
					v = 25;
					break;
			}
		}
		return new IssuedTask()
								..task = this
								..value = v;
	}
}


class DollarSigns extends CommandTask
{
	DollarSigns()
	{
		value = 2;
	}

	Map serialize()
	{
		return CommandTask.makeRadial(this, 2, 6);
	}

	void complete(int value, String code)
	{
		if(!hasLineOfInterest)
		{
			findLineOfInterest(code, "DOLLAR_SIGNS");
		}
	}

	String getIssueCommand(int value)
	{
		return "SET DOLLAR SIGNS TO $value";
	}
	
	String apply(String code)
	{
		code = code.replaceAll("DOLLAR_SIGNS", value.toString());
		return code;
	}

	String taskType()
	{
		return "DollarSigns";
	}

	String taskLabel()
	{
		return "Dollar Signs";
	}

	IssuedTask issue()
	{
		Random rand = new Random();
		int v = value;
		while(v == value)
		{
			v = rand.nextInt(5)+2;
		}
		return new IssuedTask()
								..task = this
								..value = v;
	}
}