import "dart:math";
import "command_tasks.dart";
import "icon_tasks.dart";
import "corner_radius_tasks.dart";
import "replace_widget_tasks.dart";

const int NumGameTasks = 20;

class TaskList
{
	List<CommandTask> _highPrioriy;
	List<CommandTask> _all;
	List<IssuedTask> _toIssue;
	
	TaskList()
	{
		_highPrioriy.add(new ShowFeaturedAligned());
		_highPrioriy.add(new ShowFeaturedCarousel());

		_all.add(new AddIconATask());
		_all.add(new AddIconBTask());
		_all.add(new ListCornerRadius());
		_all.add(new CarouselCornerRadius());
		_all.add(new ShowFeaturedCarousel());
	}

	void buildIssueList()
	{
		Random rand = new Random();
		const int MaxLoop = 5000;
		for(int counter = 0; _toIssue.length < NumGameTasks && counter < MaxLoop; counter++)
		{
			if(_highPrioriy.length > 0)
			{
				int index = rand.nextInt(_highPrioriy.length);
				_highPrioriy.removeAt(index).tryToIssue(_toIssue);
				continue;
			}
			int index = rand.nextInt(_all.length);
			_all[index].tryToIssue(_toIssue);
		}
	}
}