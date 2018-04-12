import "dart:io";
import "dart:convert";
import "dart:async";
import 'dart:math';
import "tasks/task_list.dart";
import "tasks/command_tasks.dart";
import "package:flutter/scheduler.dart";

enum CommandTypes { slider, radial, binary }
enum TaskStatus { complete, inProgress, failed }

class GameClient
{
    static const Duration timeBetweenTasks = const Duration(seconds: 2);
    WebSocket _socket;
    GameServer _server;
    bool _isReady = false;
    List<CommandTask> _commands = [];

    IssuedTask _currentTask;
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
        print("DEAD TO ME!");
        _sendJSONMessage("taskFail", "You're dead to me!" );
    }

    get isReady => _isReady;

    get currentTask => _currentTask;
    
    get taskStatus => _taskStatus;

    set commands(List<CommandTask> commandsList)
    {
        _commands = commandsList;

        //List<Map> serializedCommands = _commands.map((CommandTask task) { return task.serialize(); });
        List<Map> serializedCommands = new List<Map>();
        for(CommandTask task in _commands)
        {
            serializedCommands.add(task.serialize());
        }
        
        _sendJSONMessage("commandsList", serializedCommands);
    }

    List<CommandTask> get commands
    {
        return _commands;
    }

    // TODO: update this logic to use a client advance function that's called once per game loop
    // this will require storing DateTimes for expiry values and comparing them to DateTime.now.
    setCurrentTask(IssuedTask value, bool delay)
    {
        _taskStatus = TaskStatus.inProgress;
        _currentTask = value;
        if(delay)
        {
            new Timer(timeBetweenTasks, () => _sendJSONMessage("newTask", value.serialize()));
        }
        else
        {
            _sendJSONMessage("newTask", value.serialize());
        }
        
        int expiry = value.expires;// value['expiry'] as int;
        _countdown = new Timer(new Duration(seconds: delay ? expiry + timeBetweenTasks.inSeconds : expiry), () { print("FAILED THE TASK!"); return _taskStatus = TaskStatus.failed; });
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
    TaskList _taskList;
    List<GameClient> _clients = new List<GameClient>();
    double _lastFrameTime = 0.0;
    bool _inGame = false;

    GameServer()
    {
        SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
        connect();
    }

    void beginFrame(Duration timeStamp) 
	{
		final double t = timeStamp.inMicroseconds / Duration.microsecondsPerMillisecond / 1000.0;
		
		if(_lastFrameTime == 0)
		{
			_lastFrameTime = t;
			SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
			// hack to circumvent not being enable to initialize lastFrameTime to a starting timeStamp (maybe it's just the date?)
			// Is the FrameCallback supposed to pass elapsed time since last frame? timeStamp seems to behave more like a date
			return;
		}

        if(_inGame)
        {
            gameLoop();
        }

        SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
    }

    void connect()
    {
        //HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 8080)
        HttpServer.bind("10.76.253.108", 8080)
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
            // Build the full list.
            _taskList = new TaskList();
            List<CommandTask> taskTypes = new List<CommandTask>.from(_taskList.toAssign);
            int readyCount = _clients.fold<int>(0, (int count, GameClient client) { if(client.isReady) { count++; } return count; });
            //int perClient = (taskTypes.length/min(1,readyCount)).ceil();
            int perClient = 2;
            // tell every client the game has started and what their commands are...
            // build list of command id to possible values
            Random rand = new Random();
            for(var gc in _clients)
            {
                if(!gc.isReady)
                {
                    continue;
                }

                List<CommandTask> tasksForClient = new List<CommandTask>();
                while(tasksForClient.length < perClient && taskTypes.length != 0)
                {
                    tasksForClient.add(taskTypes.removeAt(rand.nextInt(taskTypes.length)));
                }
                gc.commands = tasksForClient;
                assignTask(gc, false);
            }
            _inGame = true;
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
       // print("LOOP RUNNING!");
        for(var gc in _clients)
        {
            TaskStatus st = gc.taskStatus;
            switch(st)
            {
                case TaskStatus.complete:
                    //print("COMPLETE!");
                    gc.onTaskCompleted();
                    break;
                case TaskStatus.inProgress:
                    //print("IN_PROGRESS!");
                    continue;
                case TaskStatus.failed:
                    //print("FAILED!");
                    gc.onTaskFailed();
                    break;         
            }
           // print("GETTING TASK");
            bool isAlive = assignTask(gc);
            if(!isAlive)
            {
                onGameOver();
                return;
            }
        }
    }
    
    onGameOver()
    {
        print("GAME OVER!");
        _inGame = false;
        for(var gc in _clients)
        {
            gc.gameOver();
        }
    }

    bool assignTask(GameClient client, [bool delay = true])
    {
        IssuedTask task = _taskList.nextTask(client.commands);
        if(task == null)
        {
            return false;
        }
        client.setCurrentTask(task, delay);
        return true;
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