typedef void DopamineScoreCallback(int score);
typedef void DopamineLifeLostCallback();

abstract class DopamineDelegate
{
	DopamineScoreCallback onScored;
    DopamineLifeLostCallback onLifeLost;
}