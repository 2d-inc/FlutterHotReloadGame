import "command_tasks.dart";

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