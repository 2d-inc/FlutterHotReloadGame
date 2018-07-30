import "dart:async";

import "package:rxdart/rxdart.dart";

class InGameStatus
{
    /// The Server sends over the [gridDescription] which is the list of commands that a 
    /// player will have on the screen for a single game.
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

/// This BLOC is used to communicate with the [InGame] widget.
class InGameBloc
{
    /// Keep a reference to the last element added to the [Stream]
    /// and initialize to a default 'empty' value.
    InGameStatus _last = InGameStatus.seed();
    
    BehaviorSubject<InGameStatus> _inGameController = new BehaviorSubject();
    Stream<InGameStatus> get stream => _inGameController.stream;
    Sink<InGameStatus> get sink => _inGameController.sink;

    dispose()
    {
        _inGameController.close();
    }

    /// This function takes care of 'diffing' the last element of the Stream
    /// with a new one so that any incoming new data is passed correctly to the
    /// [StreamBuilder] widgets that are listening.
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