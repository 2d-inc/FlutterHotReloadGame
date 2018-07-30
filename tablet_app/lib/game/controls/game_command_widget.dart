typedef void IssueCommandCallback(String type, int value);

abstract class GameCommand
{
	String get taskType;
}