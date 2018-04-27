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


class ImageWidthTask extends CommandTask
{
	ImageWidthTask()
	{
		value = 100;
	}

	int get finalValue
	{
		return 100;
	}

	Map serialize()
	{
		return CommandTask.makeRadial(this, 100, 132);
	}

	void complete(int value, String code)
	{
		if(!hasLineOfInterest)
		{
			findLineOfInterest(code, "IMAGE_WIDTH");
		}
	}

	String getIssueCommand(int value)
	{
		return "SET IMAGE WIDTH TO $value";
	}
	
	String apply(String code)
	{
		code = code.replaceAll("IMAGE_WIDTH", value.toString());
		return code;
	}

	String taskType()
	{
		return "ImageWidthType";
	}

	String taskLabel()
	{
		return "Image Width";
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
					v = 100;
					break;
				case 1:
					v = 108;
					break;
				case 2:
					v = 116;
					break;
				case 3:
					v = 124;
					break;
				case 4:
					v = 132;
					break;
			}
		}
		return new IssuedTask()
								..task = this
								..value = v;
	}
}
