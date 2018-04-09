import "dart:io";
import "dart:convert";

class GameClient
{
    WebSocket _socket;
    GameServer _server;
    bool _isReady;
    bool _isReadyToStart;

    GameClient(GameServer server, WebSocket socket)
    {
        _socket = socket;
        _server = server;
        _socket.listen(_dataReceived, onDone: _onDisconnected);
        _socket.pingInterval = const Duration(seconds: 5);
    }

    _onDisconnected()
    {
        print("I got disconnected! ${_socket.closeCode}");
        _server.onClientDisconnected(this);
    }

    String formatJSONMessage(String msg)
    {
        return JSON.encode({"message": msg});
    }

    void _dataReceived(message)
    {
        print("Just received ====:\n $message");
        try
        {
            var jsonMsg = JSON.decode(message);
            String msg = jsonMsg['message'];
            
            switch(msg)
            {
                case "ready":
                    _isReady = true;
                    _server.onClientReadyChanged(this);
                    _socket.add(formatJSONMessage("readyReceived"));
                    break;
                case "notReady":
                    _isReady = false;
                    _server.onClientReadyChanged(this);
                    _socket.add(formatJSONMessage("readyRemoved"));
                    break;
                case "startGame":
                    // TODO:
                    break;
                default:
                    print("MESSAGE: $jsonMsg");
                    break;
            }
        }
        on FormatException catch(e)
        {
            print("Wrong Message Formatting, not JSON: ${message}");
            print(e);
        }
    }

    get isReady => _isReady;

    set isReadyToStart(bool isIt)
    {
        if(_isReady)
        {
            _socket.add(formatJSONMessage("canStart"));
        }
    }
}

class GameServer
{
    int _readyCount = 0;
    List<GameClient> _clients = new List<GameClient>();

    GameServer()
    {
        print("Trying to create the server");
        connect();
    }

    void connect()
    {
        HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 8080)
            .then((server) async
            {
                print("Serving at ${server.address}, ${server.port}");
                await for(var request in server)
                {
                    if(WebSocketTransformer.isUpgradeRequest(request))
                    {
                        WebSocketTransformer.upgrade(request).then(_handleWebSocket);
                    }
                    else
                    {
                        // Simple request
                        request.response
                            ..headers.contentType = new ContentType("text", "plain", charset: "utf-8")
                            ..write("Hello, world")
                            ..close();   
                    }
                }
        });
    }

    onClientDisconnected(GameClient client)
    {
        this._clients.remove(client); // Could be optimized with a HashSet? Maybe too much overhead
    }

    onClientReadyChanged(GameClient client)
    {
        if(client.isReady)
        {
            _readyCount++;
        }

        if(_readyCount >= 2)
        {
            for(var gc in _clients)
            {
                gc.isReadyToStart = true;
            }
        }
    }

    onClientStartChanged(GameClient client)
    {
    }


    onGameStart()
    {
    }

    _handleWebSocket(WebSocket socket)
    {
        print("ADD WEBCLIENT! ${this._clients.length}");
        GameClient client = new GameClient(this, socket);
        _clients.add(client);
    }
}