import "dart:convert";
import "dart:math";

import "flutter_task.dart";

/// Wrapper class for all the information for a highscore:
/// - Team Initials;
/// - Final score;
/// - Global ranking;
/// - Number of participants.
class HighScore
{
	String name;
	int value;
	int idx;
    int teamSize;

	@override
	String toString()
	{
		return "$name(\u{1F465}$teamSize): $value";
	}
}

/// Maintain the information regarding all the highscores that have been registered until a certain point in time.
/// The file containing the highscores is stored at the root folder of the project, and is read and deserialized when this object is created. 
/// Helper methods are present for sorting the scores, writing them back to disk, checking if a score is in the top ten,
/// so it is visualized in the monitor screen, and removing them.
class HighScores
{
    static const highScoreFile = "/../highscores.json";
	List<HighScore> _scores = new List<HighScore>();

	List<HighScore> get scores => _scores;
	List<HighScore> get topTen => _scores.sublist(0, min(10, _scores.length));

	FlutterTask _flutterTask;

	HighScores(this._flutterTask)
	{
		_flutterTask.read(highScoreFile).then((contents)
		{
			try
			{
				var encoded = json.decode(contents);
				if(encoded is List<dynamic>)
				{
					for(dynamic item in encoded)
					{
						var value = item["value"];
						var name = item["name"];
                        var size = item["teamSize"];
						if(value is int && name is String)
						{
							_scores.add(new HighScore()
											..name = name
											..value = value
                                            ..teamSize=size);
						}
					}
				}
				sortScores();
			}
			catch(Exception)
			{
				print("No highscores.");
			}
		});
	}

	void sortScores()
	{
		_scores.sort((HighScore a, HighScore b)
		{
			return b.value-a.value;
		});

		int idx = 0;
		for(HighScore score in _scores)
		{
			score.idx = idx++;
		}
	}
	
	bool isTopTen(int value)
	{
		return _scores.indexWhere((HighScore score)
		{
			return value > score.value;
		}) < 10;
	}

	HighScore addScore(String name, int value, int teamSize)
	{
		HighScore score = new HighScore()
									..name = name
									..value = value
                                    ..teamSize = teamSize;
		_scores.add(score);
		
		sortScores();

		return score;
	}

	void save()
	{
		List<dynamic> encodedScores = _scores.map<dynamic>((HighScore score)
		{
			return {"name":score.name, "value":score.value, "teamSize": score.teamSize};
		}).toList();

		_flutterTask.write(highScoreFile, json.encode(encodedScores));
	}

    void remove(HighScore value)
    {
        _scores.remove(value);
        sortScores();
    }
}