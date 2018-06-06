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
            this.arePlayersReady: const [false] // Value corresponding to this player not being ready.
        }
    );
}

class GameConnectionBloc
{
    ConnectionInfo _last = ConnectionInfo.seed();

    BehaviorSubject<ConnectionInfo> _connectionInfoController = new BehaviorSubject();
    Stream<ConnectionInfo> get stream => _connectionInfoController.stream;
    Sink<ConnectionInfo> get sink => _connectionInfoController.sink;
    
    dispose()
    {
        _connectionInfoController.close();
    }

    setLast({ bool isConnected, bool isPlaying, bool isReady, bool canBeReady, bool markedStart, List<bool> arePlayersReady })
    {
        // Check if parameter was provided, otherwise use last
        isConnected = isConnected ?? last.isConnected;
        isPlaying = isPlaying ?? last.isPlaying;
        isReady = isReady ?? last.isReady;
        canBeReady = canBeReady ?? last.canBeReady;
        markedStart = markedStart ?? last.markedStart;
        arePlayersReady = arePlayersReady ?? last.arePlayersReady;
        var info = new ConnectionInfo(isConnected, isPlaying, isReady, canBeReady, markedStart, arePlayersReady);
        _last = info;
        _connectionInfoController.add(info);
    }

    ConnectionInfo get last => _last;
}