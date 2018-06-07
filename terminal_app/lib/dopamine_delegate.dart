typedef void DopamineScoreCallback(int score);
typedef void DopamineLifeLostCallback();

/// An interface which defines the two functions that will be called by the Delegate itself whenever needed.
abstract class DopamineDelegate
{
	DopamineScoreCallback onScored;
    DopamineLifeLostCallback onLifeLost;
}