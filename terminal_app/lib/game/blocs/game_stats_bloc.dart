import "dart:async";
import "package:rxdart/rxdart.dart";

/// The [GameStatistics] object servers the purpose of maintaing all the data
/// relevant to the game stats. This is going to be passed to Widgets such as 
/// [GameOverStats] widget that is visible at the end of a game.
class GameStatistics
{
    final int lifeScore;
    final int lives;
    final int rank;
    final int score;
    final double progress;
    final DateTime time;
    final String initials;

    GameStatistics(this.lifeScore, this.lives, this.rank, this.score, this.progress, this.time, this.initials);

    GameStatistics.seed(
        {
            this.lifeScore: 0, 
            this.lives: 0, 
            this.rank: 0, 
            this.score: 0, 
            this.progress: 0.0, 
            this.time,
            this.initials: ""
        });
    get finalScore => lifeScore * lives + score;
}

class GameStatsBloc
{
    /// Keep a reference to the last element added to the [Stream]
    /// and initialize to a default 'empty' value.
    GameStatistics _last = GameStatistics.seed();

    BehaviorSubject<GameStatistics> _gameStatsController = new BehaviorSubject();
    Sink<GameStatistics> get sink => _gameStatsController.sink;
    Stream<GameStatistics> get stream => _gameStatsController.stream;

    dispose()
    {
        _gameStatsController.close();
    }

    /// This function takes care of 'diffing' the last element of the Stream
    /// with a new one so that any incoming new data is passed correctly to the
    /// [StreamBuilder] widgets that are listening.
    setLast({ int lifeScore, int lives, int rank, int score, double progress, DateTime time, String initials })
    {
        var stats = new GameStatistics(
            lifeScore ?? last.lifeScore, 
            lives ?? last.lives, 
            rank ?? last.rank, 
            score ?? last.rank, 
            progress ?? last.progress, 
            time ?? last.time,
            initials ?? last.initials
        );
        _last = stats;
        _gameStatsController.add(stats);
    }

    /// Some convenience getters. 
    /// No setters are exposed because the setLast() function takes care of 
    /// updating any new instance of [GameStatistics], and, being final, they 
    /// can't be updated manually in any case.
    GameStatistics get last => _last;
    int get lives => _last.lives;
    int get score => _last.score;
    String get initials => _last.initials;
}