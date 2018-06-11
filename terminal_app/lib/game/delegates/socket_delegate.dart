typedef void SocketMessageCallback(jsonMessage);
typedef bool SocketReadyCallback();
typedef void SocketConnectionCallback();

abstract class SocketDelegate
{
    SocketMessageCallback onMessage;
    SocketReadyCallback onReady;
    SocketConnectionCallback onConnectionChanged;
}