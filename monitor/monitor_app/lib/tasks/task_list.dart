import "dart:math";
import "command_tasks.dart";
import "icon_tasks.dart";
import "corner_radius_tasks.dart";

const int NumGameTasks = 10;
const int AutomaticUpdateSteps = 3;

typedef String CodeUpdateStep(String code, List<CommandTask> availableTasks);

class TaskList
{
	List<CommandTask> _available = <CommandTask>
	[
		new ListCornerRadius(),
		new FeaturedCornerRadius(),
		new AppPadding(),
		new SetBackgroundColor()
	];

	List<CommandTask> toAssign = <CommandTask>
	[
		new ListCornerRadius(),
		new FeaturedCornerRadius(),
		new AppPadding(),
		new SetBackgroundColor(),
		new AddIconATask(),
		new AddIconBTask(),
		new CarouselIcons()
	];

	int _tasksCompleted = 0;
	int _tasksAssigned = 0;
	int _completionsPerUpdate = 0;
	int _appliedUpdateIndex = -1;

	List<CodeUpdateStep> _automaticUpdates = <CodeUpdateStep>
	[
		(String code, List<CommandTask> availableTasks)
		{
			return code.replaceAll("CategorySimple", "CategoryAligned");
		},
		(String code, List<CommandTask> availableTasks)
		{
			return code.replaceAll("FeaturedRestaurantSimple", "FeaturedRestaurantAligned");
		},
		(String code, List<CommandTask> availableTasks)
		{
			return code.replaceAll("RestaurantsHeaderSimple", "RestaurantsHeaderAligned");
		},
		(String code, List<CommandTask> availableTasks)
		{
			availableTasks.add(new AddIconATask());
			availableTasks.add(new AddIconBTask());
			return code.replaceAll("CategoryAligned", "CategoryDesigned");
		},
		(String code, List<CommandTask> availableTasks)
		{
			return code.replaceAll("RestaurantSimple", "RestaurantAligned");
		},
		(String code, List<CommandTask> availableTasks)
		{
			return code.replaceAll("RestaurantsHeaderAligned", "RestaurantsHeaderDesigned");
		},
		(String code, List<CommandTask> availableTasks)
		{
			return code.replaceAll("FEATURED_RESTAURANT_SIZE", "304.0");
		},
		(String code, List<CommandTask> availableTasks)
		{
			availableTasks.add(new CarouselIcons());
			return code.replaceAll("RestaurantAligned", "RestaurantDesigned");
		}
	];
	
	TaskList(this._completionsPerUpdate);

	bool get isEmpty
	{
		return _tasksAssigned > NumGameTasks;
	}
	
	completeTask(String code)
	{
		_tasksCompleted++;
		int idx = _tasksCompleted ~/ _completionsPerUpdate;
		if(_appliedUpdateIndex != idx)
		{
			_appliedUpdateIndex = idx;
			if(idx < _automaticUpdates.length)
			{
				return _automaticUpdates[idx](code, _available);
			}
		}

		return code;
	}

	IssuedTask nextTask(List<CommandTask> avoid)
	{
		//List<String> avoidTypes = avoid.map((CommandTask task) { return task.taskType(); });
		for(int sanity = 0; sanity < 100; sanity++)
		{
			List<String> avoidTypes = new List<String>();
			for(CommandTask task in avoid)
			{
				avoidTypes.add(task.taskType());
			}
			
			CommandTask firstValid = _available.firstWhere((CommandTask possibleTask)
			{
				return !avoidTypes.contains(possibleTask.taskType());
			}, orElse: () { return null; });
			if(firstValid != null)
			{
				IssuedTask issuedTask = firstValid.issue();
				if(issuedTask != null)
				{
					_tasksAssigned++;
					return issuedTask;
				}
				else
				{
					// Could not issue this command, remove it from the list.
					_available.remove(firstValid);
				}
			}
		}
		return null;
	}

	// void buildIssueList()
	// {
	// 	Random rand = new Random();
	// 	const int MaxLoop = 5000;
	// 	for(int counter = 0; _toIssue.length < NumGameTasks && counter < MaxLoop; counter++)
	// 	{
	// 		if(_highPrioriy.length > 0)
	// 		{
	// 			int index = rand.nextInt(_highPrioriy.length);
	// 			_highPrioriy.removeAt(index).tryToIssue(_toIssue);
	// 			continue;
	// 		}
	// 		int index = rand.nextInt(_available.length);
	// 		_available[index].tryToIssue(_toIssue);
	// 	}

	// 	for(IssuedTask t in _toIssue)
	// 	{
	// 		String lookingForType = t.task.taskType();
	// 		CommandTask found = toAssign.firstWhere((CommandTask t)
	// 		{
	// 			return t.taskType() == lookingForType;
	// 		}, orElse:(){ return null; });
	// 		if(found == null)
	// 		{
	// 			toAssign.add(t.task);
	// 		}
	// 	}
	// }
}