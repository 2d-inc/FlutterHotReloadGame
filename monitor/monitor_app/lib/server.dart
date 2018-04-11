import "dart:io";
import "dart:convert";

import 'dart:math';

enum CommandTypes { SLIDER, RADIAL, BINARY, TOGGLE }

class GameClient
{
    WebSocket _socket;
    GameServer _server;
    bool _isReady = false;
    List<Map> _commands = [];

    GameClient(GameServer server, WebSocket socket)
    {
        _socket = socket;
        _server = server;
        _socket.listen(_dataReceived, onDone: _onDisconnected);
        _socket.pingInterval = const Duration(seconds: 5);
    }

    _onDisconnected()
    {
        print("${this.runtimeType} disconnected! ${_socket.closeCode}");
        _server.onClientDisconnected(this);
    }

    void _dataReceived(message)
    {
        print("Just received ====:\n $message");
        try
        {
            var jsonMsg = json.decode(message);
            String msg = jsonMsg['message'];
            
            switch(msg)
            {
                case "ready":
                    _isReady = jsonMsg['payload'];
                    print("PLAYER READY? ${_isReady}");
                    _server.onClientReadyChanged();
                    break;
                case "startGame":
                    print("READY TO START");
                    _server.onClientStartChanged(this);
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

    gameOver()
    {
        _socket.add(GameServer.formatJSONMessage("gameOver", true));
    }

    get isReady => _isReady;

    set commands(List<Map> commandsList)
    {
        _commands = commandsList;
        _socket.add(GameServer.formatJSONMessage("commandsList", _commands));
    }

    set readyList(List<bool> readyPlayers)
    {
        _socket.add(GameServer.formatJSONMessage("playerList", readyPlayers));
    }

}

class GameServer
{
    List<GameClient> _clients = new List<GameClient>();

    GameServer()
    {
        connect();
    }

    static String formatJSONMessage<T>(String msg, T payload)
    {
        return json.encode({
            "message": msg,
            "payload": payload
        });
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
        this._clients.remove(client);
        onClientReadyChanged();
    }

    onClientReadyChanged()
    {
        int l = _clients.length;
        List<bool> readyList = new List(l);
        for(int i = 0; i < l; i++)
        {
            readyList[i] = _clients[i].isReady;
        }

        for(var gc in _clients)
        {
            gc.readyList = readyList;
        }
    }

    onClientStartChanged(GameClient client)
    {
        /* 
            TODO:
            iterate all the clients. 
            If everyone is ready, call game start
        */
        bool readyToStart = true;
        for(var gc in _clients)
        {
            readyToStart == readyToStart && gc.isReady;
        }
        
        if(readyToStart)
        {
            onGameStart();
        }
    }

    onGameStart()
    {
        // tell every client the game has started and what their commands are...
        // build list of command id to possible values
        for(var gc in _clients)
        {
            gc.commands = generateCommands();
        }
    }

    onGameOver()
    {
        for(var gc in _clients)
        {
            gc.gameOver();
        }
    }

    _handleWebSocket(WebSocket socket)
    {
        print("ADD WEBCLIENT! ${this._clients.length}");
        GameClient client = new GameClient(this, socket);
        _clients.add(client);
        onClientReadyChanged();
    }

    List<Map> generateCommands()
    {
        List<Map> clientCommands = [];
        var random = new Random();
        List<CommandTypes> allCommands = CommandTypes.values;
        // TODO: compute the best fit for the commands
        for(int i = 0; i < 4; i++)
        {
            int index = random.nextInt(allCommands.length);
            Map currentCommand;
            CommandTypes ct = allCommands[index];
            switch(ct)
            {
                // TODO: randomize parameters values
                case CommandTypes.BINARY:
                    currentCommand = _makeBinary("DATA CONNECTION", [ "BODY TEXT", "HEADLINE" ]);
                    break;
                case CommandTypes.RADIAL:
                    currentCommand = _makeRadial("MARGIN", 0, 40);
                    break;
                case CommandTypes.SLIDER:
                    currentCommand = _makeSlider("HEIGHT", 0, 200);
                    break;
                case CommandTypes.TOGGLE:
                    currentCommand = _makeToggle("DATA CONNECTION");
                    break;
                default:
                    print("UNKOWN COMMAND ${ct}");
                    break;
            }
            clientCommands.add(currentCommand);
        }

        return clientCommands;
    }

    static Map _makeSlider(String title, int min, int max)
    {
        return {
            "type": "GameSlider",
            "title": title,
            "min": min,
            "max": max
        };
    }

    static Map _makeRadial(String title, int min, int max)
    {
        return {
            "type": "GameRadial",
            "title": title,
            "min": min,
            "max": max
        };
    }

    static Map _makeBinary(String title, List<String> options)
    {
        return {
            "type": "GameBinaryButton",
            "title": title,
            "buttons": options
        };
    }

    static Map _makeToggle(String title)
    {
        return {
            "type": "GameToggle",
            "title": title
        };
    }
}