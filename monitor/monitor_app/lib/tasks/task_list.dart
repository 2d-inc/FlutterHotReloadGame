import "dart:math";
import "command_tasks.dart";
import "icon_tasks.dart";
import "corner_radius_tasks.dart";
import "replace_widget_tasks.dart";

const int NumGameTasks = 10;

class TaskList
{
	List<CommandTask> _highPrioriy = new List<CommandTask>();
	List<CommandTask> _all = new List<CommandTask>();
	List<IssuedTask> _toIssue = new List<IssuedTask>();

	List<CommandTask> toAssign = new List<CommandTask>();
	
	TaskList()
	{
		_highPrioriy.add(new ShowFeaturedAligned());
		_highPrioriy.add(new ShowFeaturedCarousel());

		_all.add(new AddIconATask());
		_all.add(new AddIconBTask());
		_all.add(new ListCornerRadius());
		_all.add(new CarouselCornerRadius());
		_all.add(new ShowFeaturedCarousel());

		buildIssueList();
	}

	bool get isEmpty
	{
		return _toIssue.length == 0;
	}
	
	IssuedTask nextTask(List<CommandTask> avoid)
	{
		if(_toIssue.length == 0)
		{
			return null;
		}

		//List<String> avoidTypes = avoid.map((CommandTask task) { return task.taskType(); });
		List<String> avoidTypes = new List<String>();
		for(CommandTask task in avoid)
		{
			avoidTypes.add(task.taskType());
		}

		IssuedTask firstValid = _toIssue.firstWhere((IssuedTask possibleTask)
		{
			return !avoidTypes.contains(possibleTask.task.taskType());
		}, orElse: () { return null; });
		if(firstValid != null)
		{
			_toIssue.remove(firstValid);
			return firstValid;
		}
		return null;
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

		for(IssuedTask t in _toIssue)
		{
			String lookingForType = t.task.taskType();
			CommandTask found = toAssign.firstWhere((CommandTask t)
			{
				return t.taskType() == lookingForType;
			}, orElse:(){ return null; });
			if(found == null)
			{
				toAssign.add(t.task);
			}
		}
	}
}