abstract class CommandTask
{
    bool isPlayable = false;
    DateTime lastIssued = new DateTime.now().subtract(const Duration(days:7));
    int value = 0;
    int _lineOfInterest;
	String apply(String code);
	void complete(int value, String code);
    void setCurrentValue(int value)
    {
        this.value = value;
    }
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

    bool isDelayed() { return false; }

    bool get hasLineOfInterest
    {
        return _lineOfInterest != null;
    }

    int get finalValue
    {
        return -1;
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

class IssuedTask
{
	CommandTask task;
	int value;
	int expires = 15;

	Map serialize()
	{
		Map map = {
			"message":task.getIssueCommand(value),
			"expiry":expires
		};
		return map;
	}
}