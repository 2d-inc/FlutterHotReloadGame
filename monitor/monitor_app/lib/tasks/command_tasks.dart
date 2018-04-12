abstract class CommandTask
{
	String apply(String code);
	void complete(bool success, int value);
	String taskType();
	String taskLabel();
	void tryToIssue(List<IssuedTask> currentQueue);
}

class IssuedTask
{
	CommandTask task;
	int value;
}