abstract class CommandTask
{
	String apply(String code);
	void complete(bool success, int value);
	String taskType();
	String taskLabel();
	String getIssueCommand(int value);
	void tryToIssue(List<IssuedTask> currentQueue);
	Map serialize();

    static Map makeSlider(String title, int min, int max)
    {
        return {
            "type": "GameSlider",
            "title": title,
            "min": min,
            "max": max
        };
    }

    static Map makeRadial(String title, int min, int max)
    {
        return {
            "type": "GameRadial",
            "title": title,
            "min": min,
            "max": max
        };
    }

    static Map makeBinary(String title, List<String> options)
    {
        return {
            "type": "GameBinaryButton",
            "title": title,
            "buttons": options
        };
    }

    static Map makeToggle(String title)
    {
        return {
            "type": "GameToggle",
            "title": title
        };
    }
}

class IssuedTask
{
	CommandTask task;
	int value;
	int expires = 20;

	Map serialize()
	{
		Map map = {
			"message":task.getIssueCommand(value),
			"expiry":expires
		};
		return map;
	}
}