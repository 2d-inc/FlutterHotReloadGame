import "dart:async";

import "package:rxdart/rxdart.dart";

class ConnectionInfo
{
    bool isConnected;
    bool isPlaying;
    bool isReady;
    bool canBeReady;
    bool markedStart;
    List<bool> arePlayersReady;

    ConnectionInfo(this.isConnected, this.isPlaying, this.isReady, this.canBeReady, this.markedStart, this.arePlayersReady);
    ConnectionInfo.seed(
        {
            this.isConnected: false,
            this.isPlaying: false,
            this.isReady: false,
            this.canBeReady: false,
            this.markedStart: false,
            this.arePlayersReady: const [false] /// Initialization value corresponding to the local player not being ready.
        }
    );
}

/// This BLOC is used to communicate with the [_TerminalState] and [LobbyWidget].
class GameConnectionBloc
{
    /// Keep a reference to the last element added to the [Stream]
    /// and initialize to a default 'empty' value.
    ConnectionInfo _last = ConnectionInfo.seed();

    BehaviorSubject<ConnectionInfo> _connectionInfoController = new BehaviorSubject();
    Stream<ConnectionInfo> get stream => _connectionInfoController.stream;
    Sink<ConnectionInfo> get sink => _connectionInfoController.sink;
    
    dispose()
    {
        _connectionInfoController.close();
    }

    /// This function takes care of 'diffing' the last element of the Stream
    /// with a new one so that any incoming new data is passed correctly to the
    /// [StreamBuilder] widgets that are listening.
    setLast({ bool isConnected, bool isPlaying, bool isReady, bool canBeReady, bool markedStart, List<bool> arePlayersReady })
    {
        var ci = new ConnectionInfo(
            isConnected ?? last.isConnected, 
            isPlaying ?? last.isPlaying, 
            isReady ?? last.isReady, 
            canBeReady ?? last.canBeReady, 
            markedStart ?? last.markedStart, 
            arePlayersReady ?? last.arePlayersReady
        );
        _last = ci;
        _connectionInfoController.add(ci);
    }

    ConnectionInfo get last => _last;
}