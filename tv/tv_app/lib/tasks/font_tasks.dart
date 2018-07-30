import "dart:math";
import "command_tasks.dart";

class FontSizeCommand extends CommandTask
{
	FontSizeCommand()
	{
		value = 12;
	}

	Map serialize()
	{
		return CommandTask.makeRadial(this, 12, 16);
	}

	int get finalValue
	{
		return 15;
	}

	void complete(int value, String code)
	{
		if(!hasLineOfInterest)
		{
			findLineOfInterest(code, "MAIN_FONT_SIZE");
		}
	}
	
	String getIssueCommand(int value)
	{
		return "SET FONT SIZE TO $value";
	}

	String apply(String code)
	{
		code = code.replaceAll("MAIN_FONT_SIZE", value.toString() + ".0");
		return code;
	}

	String taskType()
	{
		return "FontSize";
	}

	String taskLabel()
	{
		return "Set Font Size";
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
					v = 12;
					break;
				case 1:
					v = 13;
					break;
				case 2:
					v = 14;
					break;
				case 3:
					v = 15;
					break;
				case 4:
					v = 16;
					break;
			}
		}
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