import "dart:math";

import "command_tasks.dart";

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