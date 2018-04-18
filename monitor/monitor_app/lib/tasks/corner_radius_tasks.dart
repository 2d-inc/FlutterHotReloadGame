import "dart:math";
import "command_tasks.dart";

class ListCornerRadius extends CommandTask
{
	int _cornerRadius = 0;

	Map serialize()
	{
		return CommandTask.makeRadial(this, 0, 60);
	}

	void complete(int value, String code)
	{
		_cornerRadius = value;
		if(!hasLineOfInterest)
		{
			findLineOfInterest(code, "LIST_CORNER_RADIUS");
		}
	}

	String getIssueCommand(int value)
	{
		return "SET LIST CORNER RADIUS TO $value";
	}
	
	String apply(String code)
	{
		code = code.replaceAll("LIST_CORNER_RADIUS", _cornerRadius.toString() + ".0");
		return code;
	}

	String taskType()
	{
		return "ListRadius";
	}

	String taskLabel()
	{
		return "Set List Corner Radius";
	}

	IssuedTask issue()
	{
		Random rand = new Random();
		int v = value;
		while(v == value)
		{
			switch(rand.nextInt(3))
			{
				case 0:
					v = 0;
					break;
				case 1:
					v = 15;
					break;
				case 2:
					v = 60;
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
	int _cornerRadius = 0;

	Map serialize()
	{
		return CommandTask.makeRadial(this, 0, 30);
	}

	void complete(int value, String code)
	{
		_cornerRadius = value;
		if(!hasLineOfInterest)
		{
			findLineOfInterest(code, "FEATURED_CORNER_RADIUS");
		}
	}
	
	String getIssueCommand(int value)
	{
		return "SET FEATURED CORNER RADIUS TO $value";
	}

	String apply(String code)
	{
		code = code.replaceAll("FEATURED_CORNER_RADIUS", _cornerRadius.toString() + ".0");
		return code;
	}

	String taskType()
	{
		return "FeaturedRadius";
	}

	String taskLabel()
	{
		return "Set Featured Corner Radius";
	}

	IssuedTask issue()
	{
		Random rand = new Random();
		int v = value;
		while(v == value)
		{
			switch(rand.nextInt(3))
			{
				case 0:
					v = 7;
					break;
				case 1:
					v = 15;
					break;
				case 2:
					v = 30;
					break;
			}
		}
		return new IssuedTask()
								..task = this
								..value = v;
	}
}

class AppPadding extends CommandTask
{
	int _padding = 20;

	Map serialize()
	{
		return CommandTask.makeRadial(this, 0, 60);
	}

	void complete(int value, String code)
	{
		_padding = value;
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
		code = code.replaceAll("APP_PADDING", _padding.toString() + ".0");
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
					v = 15;
					break;
				case 1:
					v = 30;
					break;
				case 2:
					v = 45;
					break;
				case 3:
					v = 60;
					break;
				case 4:
					v = 0;
					break;
			}
		}
		return new IssuedTask()
								..task = this
								..value = v;
	}
}

class FontSizeCommand extends CommandTask
{
	Map serialize()
	{
		return CommandTask.makeRadial(this, 8, 20);
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
		return "SET FEATURED CORNER RADIUS TO $value";
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
					v = 8;
					break;
				case 1:
					v = 11;
					break;
				case 2:
					v = 14;
					break;
				case 3:
					v = 17;
					break;
				case 4:
					v = 20;
					break;
			}
		}
		return new IssuedTask()
								..task = this
								..value = v;
	}
}