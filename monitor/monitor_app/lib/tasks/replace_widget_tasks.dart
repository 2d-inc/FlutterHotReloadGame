import "dart:math";
import "command_tasks.dart";

class ShowFeaturedAligned extends CommandTask
{
	int _featuredItemSize = 0;

	Map serialize()
	{
		return CommandTask.makeSlider(this, 0, 350);
	}
	
	String getIssueCommand(int value)
	{
		return "SET FEATURED ITEM SIZE TO $value!";
	}

	void complete(bool success, int value)
	{
		_featuredItemSize = value;
	}

	String apply(String code)
	{
		if(_featuredItemSize != 0)
		{
			code.replaceAll("FeaturedRestaurantSimple", "FeaturedRestaurantAligned");
		}
		
		return code;
	}

	String taskType()
	{
		return "FeaturedSize";
	}

	String taskLabel()
	{
		return "Set Featured Item Size";
	}

	bool doesAutoApply()
	{
		return true;
	}

	void tryToIssue(List<IssuedTask> currentQueue)
	{
		currentQueue.add(new IssuedTask()..task = this
										..value = 10);
	}
}

class ShowFeaturedCarousel extends CommandTask
{
	int _featuredItemSize = 0;

	Map serialize()
	{
		return CommandTask.makeSlider(this, 0, 350);
	}

	void complete(bool success, int value)
	{
		_featuredItemSize = value;
	}

	String apply(String code)
	{
		if(_featuredItemSize > 0)
		{
			code.replaceAll("FEATURED_RESTAURANT_SIZE", _featuredItemSize.toString() + ".0");
		}
		
		return code;
	}

	String taskType()
	{
		return "FeaturedSize";
	}

	String taskLabel()
	{
		return "Set Featured Item Size";
	}

	String getIssueCommand(int value)
	{
		return "SET FEATURED ITEM SIZE TO $value!";
	}

	bool doesAutoApply()
	{
		return true;
	}

	void tryToIssue(List<IssuedTask> currentQueue)
	{
		// allow this task if something before us showed the aligned feature
		if(currentQueue.indexWhere((IssuedTask t) { return t.task is ShowFeaturedAligned; }) == -1)
		{
			return;
		}

		int last = currentQueue.lastIndexWhere((IssuedTask t) { return t.task is ShowFeaturedCarousel; });
		if(last == -1)
		{
			currentQueue.add(new IssuedTask()..task = this
										..value = 304);
		}
		else
		{
			ShowFeaturedCarousel c = currentQueue[last].task as ShowFeaturedCarousel;
			currentQueue.add(new IssuedTask()..task = this
										..value = c._featuredItemSize == 304 ? 350 : 304);
		}
	}
}

class CategoryFontWeight extends CommandTask
{
	int _fontWeight = 0;

	Map serialize()
	{
		return CommandTask.makeSlider(this, 0, 350);
	}

	void complete(bool success, int value)
	{
		_fontWeight = value;
	}

	String getIssueCommand(int value)
	{
		return "SET FONT WEIGHT TO $value!";
	}

	String apply(String code)
	{
		code.replaceAll("CATEGORY_FONT_WEIGHT", _fontWeight.toString());
		if(_fontWeight != 0)
		{
			code.replaceAll("CategorySimple", "CategoryAligned");
		}
		
		return code;
	}

	String taskType()
	{
		return "ListRadius";
	}

	String taskLabel()
	{
		return "Set Featured Item Size";
	}

	bool doesAutoApply()
	{
		return true;
	}

	void tryToIssue(List<IssuedTask> currentQueue)
	{
		Random rand = new Random();
		switch(rand.nextInt(2))
		{
			case 0:
				currentQueue.add(new IssuedTask()..task = this
													..value = 305);
				break;
			case 1:
				currentQueue.add(new IssuedTask()..task = this
													..value = 405);
				break;
		}
	}
}