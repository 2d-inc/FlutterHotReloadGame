typedef void SocketMessageCallback(jsonMessage);
typedef bool SocketReadyCallback();

abstract class SocketDelegate
{
    SocketMessageCallback onMessage;
    SocketReadyCallback onReady;
}