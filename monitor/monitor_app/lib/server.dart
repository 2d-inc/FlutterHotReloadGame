import "dart:io";
import "dart:convert";
import "dart:async";
import 'dart:math';

enum CommandTypes { slider, radial, binary }
enum TaskStatus { complete, inProgress, failed }

class GameClient
{
    static const Duration timeBetweenTasks = const Duration(seconds: 1);
    WebSocket _socket;
    GameServer _server;
    bool _isReady = false;
    List<Map> _commands = [];

    Map _currentTask;
    TaskStatus _taskStatus;
    Timer _countdown;

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
                case "clientInput":
                    var payload = jsonMsg['payload'];
                    _server.onClientInput(payload);
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
    
    reset()
    {
        _taskStatus = null;
        _currentTask = null;
        _countdown.cancel();
    }

    gameOver()
    {
        reset();
        _sendJSONMessage("gameOver", true);
    }

    void onTaskCompleted()
    {
        _countdown.cancel();
        _sendJSONMessage("taskComplete", "Like a glove!");
    }

    void onTaskFailed()
    {
        _sendJSONMessage("taskFail", "You're dead to me!" );
    }

    get isReady => _isReady;

    get currentTask => _currentTask;
    
    get taskStatus => _taskStatus;

    set commands(List<Map> commandsList)
    {
        _commands = commandsList;
        _sendJSONMessage("commandsList", _commands);
    }

    // TODO: use Task object instead of Map
    set currentTask(Map value)
    {
        _taskStatus = TaskStatus.inProgress;
        _currentTask = value;
        new Timer(timeBetweenTasks, () => _sendJSONMessage("newTask", value));
        
        int expiry = value['expiry'] as int;
        _countdown = new Timer(new Duration(seconds: expiry), () => _taskStatus = TaskStatus.failed);
    }

    set readyList(List<bool> readyPlayers)
    {
        _sendJSONMessage("playerList", readyPlayers);
    }

    void _sendJSONMessage<T>(String msg, T payload)
    {
        var message = json.encode({
            "message": msg,
            "payload": payload
        });
        _socket.add(message);
    }

}

class GameServer
{
    List<GameClient> _clients = new List<GameClient>();
    Timer loopTimer;

    GameServer()
    {
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
        bool readyToStart = true;
        for(var gc in _clients)
        {
            readyToStart == readyToStart && gc.isReady;
        }
        
        if(readyToStart)
        {
            // tell every client the game has started and what their commands are...
            // build list of command id to possible values
            for(var gc in _clients)
            {
                gc.commands = generateCommands();
            }

            // Start game!
            loopTimer = new Timer.periodic(const Duration(milliseconds: 1000), (timer) => gameLoop());
        }
    }

    onClientInput(Map input)
    {
        var inputType = input['type'];
        var inputValue = input['value'];
        for(var gc in _clients)
        {
            if(gc.currentTask['type'] == inputType && gc.currentTask['value'] == inputValue)
            {
                gc.taskStatus == TaskStatus.complete;
            }
        }
    }

    void gameLoop()
    {
        print("LOOP RUNNING!");
        for(var gc in _clients)
        {
            TaskStatus st = gc.taskStatus;
            switch(st)
            {
                case TaskStatus.complete:
                    print("COMPLETE!");
                    gc.onTaskCompleted();
                    break;
                case TaskStatus.inProgress:
                    print("IN_PROGRESS!");
                    continue;
                case TaskStatus.failed:
                    print("FAILED!");
                    gc.onTaskFailed();
                    break;         
            }
            print("GETTING TASK");
            bool isAlive = assignTask(gc);
            if(!isAlive)
            {
                onGameOver();
                return;
            }
            print("ASSIGN TASK $gc!");
        }
    }
    
    onGameOver()
    {
        print("GAME OVER!");
        assignedTasks = 0;
        loopTimer.cancel();
        for(var gc in _clients)
        {
            gc.gameOver();
        }
    }

    // TODO: remove
    static int assignedTasks = 0;
    static const int MAX_TASKS = 2;

    bool assignTask(GameClient client)
    {
        // TODO: Select the task from the bucket of available tasks
        if(assignedTasks < MAX_TASKS)
        {
            assignedTasks++;
            client.currentTask = {
                "message": "Set padding to 20",
                "expiry": 5
            };
            return true;
        }
        else
        {
            return false;
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
                case CommandTypes.binary:
                    currentCommand = _makeBinary("DATA CONNECTION", [ "BODY TEXT", "HEADLINE" ]);
                    break;
                case CommandTypes.radial:
                    currentCommand = _makeRadial("MARGIN", 0, 40);
                    break;
                case CommandTypes.slider:
                    currentCommand = _makeSlider("HEIGHT", 0, 200);
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