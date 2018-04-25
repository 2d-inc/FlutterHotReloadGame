import "dart:io";
import "dart:convert";
import "dart:math";
import "flutter_task.dart";

class HighScore
{
	String name;
	int value;

	@override
	String toString()
	{
		return "$name: $value";
	}
}

const highScoreFile = "/../highscores.json";

class HighScores
{
	List<HighScore> _scores = new List<HighScore>();

	List<HighScore> get scores => _scores;
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
						if(value is int && name is String)
						{
							_scores.add(new HighScore()
											..name = name
											..value = value);
						}
					}
				}
			}
			catch(Exception)
			{
				print("No highscores.");
			}
		});
	}

	int addScore(String name, int value)
	{
		_scores.add(new HighScore()
									..name = name
									..value = value);

		_scores.sort((HighScore a, HighScore b)
		{
			return b.value-a.value;
		});

		_scores = _scores.sublist(0, min(10, _scores.length));
		
		return _scores.indexWhere((HighScore score)
		{
			return score.name == name && score.value == value;
		});
	}

	void save()
	{
		List<dynamic> encodedScores = _scores.map<dynamic>((HighScore score)
		{
			return {"name":score.name, "value":score.value};
		}).toList();

		_flutterTask.write(highScoreFile, json.encode(encodedScores));
	}
}