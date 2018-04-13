abstract class CommandTask
{
	String apply(String code);
	void complete(bool success, int value);
	String taskType();
	String taskLabel();
	String getIssueCommand(int value);
	void tryToIssue(List<IssuedTask> currentQueue);
	Map serialize();

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

class IssuedTask
{
	CommandTask task;
	int value;
	int expires = 10;

	Map serialize()
	{
		Map map = {
			"message":task.getIssueCommand(value),
			"expiry":expires
		};
		return map;
	}
}