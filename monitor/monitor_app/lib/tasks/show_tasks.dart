import "command_tasks.dart";

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