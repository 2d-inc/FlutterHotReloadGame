import "dart:math";
import "command_tasks.dart";
import "icon_tasks.dart";
import "corner_radius_tasks.dart";

typedef String CodeUpdateStep(String code, TaskList list);

class TaskList
{
	List<CommandTask> _available = <CommandTask>[];

	List<CommandTask> allTasks = <CommandTask>
	[
		new FontSizeCommand(),
		new ListCornerRadius(),
		new FeaturedCornerRadius(),
		new AppPadding(),
		new SetBackgroundColor(),
		new AddIconATask(),
		new AddIconBTask(),
		new CarouselIcons(),
		new AddImages(),
		new ShowRatings(),
		new ShowDeliveryTimes(),
		new DollarSigns(),
		new CondenseListItems(),
		new CategoryFontWeight(),
		new ImageWidthTask(),
		new FontFamily()
	];

	int _tasksCompleted = 0;
	int _tasksAssigned = 0;
	int _completionsPerUpdate = 0;
	int _appliedUpdateIndex = -1;
	bool _isDone = false;

	Random _rand = new Random();

	List<CodeUpdateStep> _automaticUpdates = <CodeUpdateStep>
	[
		(String code, TaskList list)
		{
			return code.replaceAll("CategorySimple", "CategoryAligned");
		},
		(String code, TaskList list)
		{
			return code.replaceAll("FeaturedRestaurantSimple", "FeaturedRestaurantAligned");
		},
		(String code, TaskList list)
		{
			return code.replaceAll("RestaurantsHeaderSimple", "RestaurantsHeaderAligned");
		},
		(String code, TaskList list)
		{
			list.makeTaskAvailable("IconA");
			list.makeTaskAvailable("IconB");
			return code.replaceAll("CategoryAligned", "CategoryDesigned");
		},
		(String code, TaskList list)
		{
			return code.replaceAll("ListRestaurantSimple", "ListRestaurantAligned");
		},
		(String code, TaskList list)
		{
			return code.replaceAll("RestaurantsHeaderAligned", "RestaurantsHeaderDesigned");
		},
		(String code, TaskList list)
		{

			list.makeTaskAvailable("CarouselIconType");
			return code.replaceAll("FEATURED_RESTAURANT_SIZE", "304.0");
		},
		(String code, TaskList list)
		{
			//availableTasks.add(new AddImages());
			return code.replaceAll("ListRestaurantAligned", "ListRestaurantDesigned");
		}
	];
	
	TaskList(this._completionsPerUpdate)
	{
		for(CommandTask task in allTasks)
		{
			if(!task.isDelayed())
			{
				_available.add(task);
			}
		}
	}

	bool get isEmpty
	{
		return _isDone;
	}
	
	bool get gotFinalValues
	{
		for(CommandTask task in allTasks)
		{
			if(task.isPlayable && task.finalValue != -1 && task.value != task.finalValue)
			{
				print("TASK INCOMPLETE $task ${task.value} ${task.finalValue}");
				return false;
			}
		}
		print("SHOULD BE DONE");
		return true;
	}

	bool get isIssuingFinalValues
	{
		return (_tasksCompleted ~/ _completionsPerUpdate) >= _automaticUpdates.length;
	}

	void makeTaskAvailable(String type)
	{
		for(CommandTask task in allTasks)
		{
			if(task.taskType() == type)
			{
				if(_available.indexOf(task) == -1)
				{
					_available.add(task);
				}
				return;
			}
		}
	}

	void prepForFinals()
	{
		for(CommandTask task in allTasks)
		{
			task.prepareForFinal();
		}
	}

	String completeTask(String code)
	{
		_tasksCompleted++;
		int idx = _tasksCompleted ~/ _completionsPerUpdate;

		if(isIssuingFinalValues && gotFinalValues)
		{
			_isDone = true;
		}

		if(_appliedUpdateIndex != idx)
		{
			_appliedUpdateIndex = idx;
			if(idx < _automaticUpdates.length)
			{
				return _automaticUpdates[idx](code, this);
			}
		}

		return code;
	}

	double get progress
	{
		return (_tasksCompleted / (_completionsPerUpdate*_automaticUpdates.length)).clamp(0.0, 1.0);
	}

	void setNonPlayableToFinal()
	{
		for(CommandTask task in allTasks)
		{
			if(!task.isPlayable)
			{
				print("SETTING NON PLAYABLE $task to ${task.finalValue}");
				task.setCurrentValue(task.finalValue);
			}
		}
	}

	CommandTask setTaskValue(String taskType, int value)
	{
		for(CommandTask task in allTasks)
		{
			if(task.taskType() == taskType)
			{
				task.setCurrentValue(value);
				return task;
			}
		}
		return null;
	}

	String transformCode(String code)
	{
		for(CommandTask task in allTasks)
		{
			code = task.apply(code);
		}
		return code;
	}
	
	IssuedTask nextTask(List<CommandTask> avoid, {double timeMultiplier = 1.0, List<CommandTask> lowerChance})
	{
		if(isEmpty)
		{
			return null;
		}
		const int highChanceWeight = 3;
		const int lowChanceWeight = 1;
		const int lowerWeightSeconds = 8;

		DateTime now = new DateTime.now();
		const int maxSanity = 10;
		for(int sanity = 0; sanity < maxSanity; sanity++)
		{
			List<CommandTask> valid = new List<CommandTask>();
			for(CommandTask task in _available)
			{
				if(!task.isPlayable)
				{
					// A widget for this task wasn't assigned to any player.
					// This can happen if there are more tasks assignable than
					// total number of widget slots for all clients.
					// For example: two players (clients)
					// Widgets total: 16
					// The clients can only show a combined set of 10 widgets
					// So the last 6 cannot be assigned.
					// We track this by marking isPlayable to true when widgets
					// are assigned to clients at the start of the game.
					continue;
				}
				// Certain tasks we want to make sure do not get issued
				// We leave this up to the implementer but generally this
				// is the list of tasks that are already assigned.
				CommandTask avoidTask = avoid.firstWhere((CommandTask check)
				{
					return check.taskType() == task.taskType();
				}, orElse:()=>null);
				
				if(avoidTask == null)
				{
					// We also allow for a list of lower chance tasks.
					// If the task we are checking is in this list, we add it
					// less times to our valid stack such that it has lower
					// odds of being picked.
					CommandTask lowChanceTask = lowerChance.firstWhere((CommandTask check)
					{
						return check.taskType() == task.taskType();
					}, orElse:()=>null);
					
					int weight = lowChanceTask == null ? highChanceWeight : lowChanceWeight;

					
					/*if(sanity == maxSanity-1)
					{
						// give everything a weight of three if we're desperate for a task.
						weight = 3;
					}
					else */if(isIssuingFinalValues)
					{
						//print("ISSUING FINALS");
						// When issuing final values, don't issue tasks that have already reached completion.
						// Don't assign tasks that a finalValue of -1, this means their final values are not important.
						if(task.finalValue == -1 || task.value == task.finalValue)
						{
							weight = 0;
						}
					}
					else
					{
						// Alter weights based on time of issue. Don't do this while in final task assignment.
						int secondsSinceIssue = now.difference(task.lastIssued).inSeconds;
						
						if(secondsSinceIssue < lowerWeightSeconds)
						{
							// Task was issued recently, don't re-issue it.
							weight = 0;
						}
						else
						{
							// Weight task by lowerWeightSeconds since issue (provided it's less than the currently established weight).
							// This lets task gradually come back to high chance after 30 seconds.
							weight = min(weight, ((secondsSinceIssue-lowerWeightSeconds)/lowerWeightSeconds).floor());
						}
					}
					
					for(int i = 0; i < weight; i++)
					{
						valid.add(task);
					}
				}
			}
			if(valid.length == 0)
			{
				return null;
			}
			CommandTask chosenTask = valid[_rand.nextInt(valid.length)];
			IssuedTask issuedTask = isIssuingFinalValues ? (new IssuedTask()
								..task = chosenTask
								..value = chosenTask.finalValue) : chosenTask.issue();
			//print("TASKS IN LIST $valid | $issuedTask | $avoid");
			if(issuedTask != null)
			{
				chosenTask.lastIssued = new DateTime.now();
				_tasksAssigned++;
				issuedTask.expires = (issuedTask.expires*timeMultiplier).round();
				return issuedTask;
			}
			else
			{
				// Could not issue this command, remove it from the list.
				_available.remove(chosenTask);
			}
		}
		return null;
	}
}