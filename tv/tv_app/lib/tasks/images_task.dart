import "dart:math";

import "command_tasks.dart";

class AddImages extends CommandTask
{
	List<String> options = ["REMOVE IMAGES", "ADD IMAGES"];
	List<String> values = ["false", "true"];

	AddImages()
	{
		value = 1;
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
			findLineOfInterest(code, "HAVE_IMAGES");
		}
	}

	String getIssueCommand(int value)
	{
		String name = options[value];
		return "$name!";
	}

	String apply(String code)
	{
		return code.replaceAll("HAVE_IMAGES", values[this.value]);
	}

	String taskType()
	{
		return "ShowImagesType";
	}

	String taskLabel()
	{
		return "Images";
	}

	IssuedTask issue()
	{
		int v = value == 1 ? 0 : 1;

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