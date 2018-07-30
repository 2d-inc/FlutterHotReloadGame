/// This class is an interface for all the tasks that are sent to each player during a game.
/// Each of the inheriting classes will be responsible for vital tasks such as:
/// - [apply()] to build the command that'll replace the string into the Simulator app code template;
/// - [complete()] to find the correct line that needs to be highlighted upon a task completion
/// - [serialize()] to create the right type of command that'll be sent over to the player;
/// - [getIssueCommand()] to get the String that'll be delivered to the clients;
/// - [issue()] to select a random value between those available.
abstract class CommandTask
{
    int value = 0;
    int _lineOfInterest;
    bool isPlayable = false;
    DateTime lastIssued = new DateTime.now().subtract(const Duration(days:7));

	String apply(String code);
	void complete(int value, String code);
	String taskType();
	String taskLabel();
	String getIssueCommand(int value);
	IssuedTask issue();
	Map serialize();

    void prepareForFinal() {}

    @override
    String toString()
    {
        return taskLabel();
    }

    bool isDelayed() => false;

    bool get hasLineOfInterest => (_lineOfInterest != null);
    
    int get finalValue => -1;

    void setCurrentValue(int value)
    {
        this.value = value;
    }

    void findLineOfInterest(String code, String match)
    {
        int idx = code.indexOf(match);
        _lineOfInterest = 0;
        for(int i = 0; i < idx; i++)
        {
            if(code[i] == '\n')
            {
                _lineOfInterest++;
            }
        }
    }

    int get lineOfInterest
    {
        return _lineOfInterest ?? 0;
    }

    static Map makeSlider(CommandTask task, int min, int max)
    {
        return {
            "type": "GameSlider",
            "title": task.taskLabel(),
            "taskType": task.taskType(),
            "min": min,
            "max": max
        };
    }

    static Map makeRadial(CommandTask task, int min, int max)
    {
        return {
            "type": "GameRadial",
            "title": task.taskLabel(),
            "taskType": task.taskType(),
            "min": min,
            "max": max
        };
    }

    static Map makeBinary(CommandTask task, List<String> options)
    {
        return {
            "type": "GameBinaryButton",
            "title": task.taskLabel(),
            "taskType": task.taskType(),
            "buttons": options
        };
    }

    static Map makeToggle(CommandTask task)
    {
        return {
            "type": "GameToggle",
            "title": task.taskLabel(),
            "taskType": task.taskType()
        };
    }
}

/// "Packaging" for the [CommandTask]: whenever one of its implementations calls [issue()], 
/// the [TaskList] class performs a series of checks and updates the [expires] field if necessary.
class IssuedTask
{
	CommandTask task;
	int value;
	int expires = 15;

    /// Serialize the current tasks so that it contains the String that the client devices need to show
    /// for the game to progress, and the expiry time to be in sync with the server.
	Map serialize()
	{
		Map map = {
			"message":task.getIssueCommand(value),
			"expiry":expires
		};
		return map;
	}
}