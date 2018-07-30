import "dart:math";
import "command_tasks.dart";

class AppPadding extends CommandTask
{
	AppPadding()
	{
		value = 8;
	}

	int get finalValue
	{
		return 20;
	}

	Map serialize()
	{
		return CommandTask.makeRadial(this, 8, 24);
	}

	void complete(int value, String code)
	{
		if(!hasLineOfInterest)
		{
			findLineOfInterest(code, "APP_PADDING");
		}
	}
	
	String getIssueCommand(int value)
	{
		return "SET PADDING TO $value";
	}

	String apply(String code)
	{
		code = code.replaceAll("APP_PADDING", value.toString() + ".0");
		return code;
	}

	String taskType()
	{
		return "AppPadding";
	}

	String taskLabel()
	{
		return "Set Padding";
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
					v = 8;
					break;
				case 1:
					v = 12;
					break;
				case 2:
					v = 16;
					break;
				case 3:
					v = 20;
					break;
				case 4:
					v = 24;
					break;
			}
		}
		return new IssuedTask()
								..task = this
								..value = v;
	}
}