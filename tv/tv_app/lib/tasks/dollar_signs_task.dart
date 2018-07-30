import "dart:math";
import "command_tasks.dart";

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