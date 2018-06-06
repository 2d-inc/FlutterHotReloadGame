import "dart:async";
import "package:rxdart/rxdart.dart";

class InGameStatus
{
    final List gridDescription;
    final bool isOver;
    final bool hasWon;
    final bool showStats;

    InGameStatus(
        this.gridDescription,
        this.isOver,
        this.hasWon,
        this.showStats
    );

    InGameStatus.seed(
        {
            this.gridDescription: const [],
            this.isOver: false,
            this.hasWon: false,
            this.showStats: false
        }
    );
}

class InGameBloc
{
    InGameStatus _last = InGameStatus.seed();
    BehaviorSubject<InGameStatus> _inGameController = new BehaviorSubject();
    Stream<InGameStatus> get stream => _inGameController.stream;
    Sink<InGameStatus> get sink => _inGameController.sink;

    dispose()
    {
        _inGameController.close();
    }

    setLast({List gridDescription, bool isOver, bool hasWon, bool showStats})
    {
        var status = new InGameStatus(
            gridDescription ?? last.gridDescription, 
            isOver ?? last.isOver, 
            hasWon ?? last.hasWon, 
            showStats ?? last.showStats
        );
        _last = status;
        _inGameController.add(status);
    }

    InGameStatus get last => _last;
}