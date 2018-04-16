import "dart:io";
import "dart:convert";
import "dart:async";
import 'dart:math';
import "tasks/task_list.dart";
import "tasks/icon_tasks.dart";
import "tasks/command_tasks.dart";
import "package:flutter/scheduler.dart";
import 'flutter_task.dart';

enum CommandTypes { slider, radial, binary }
enum TaskStatus { complete, inProgress, failed, noMore }
typedef void UpdateCodeCallback(String code, int line);

class GameClient
{
    static const Duration timeBetweenTasks = const Duration(seconds: 2);
    WebSocket _socket;
    GameServer _server;

    bool _isReady = false;
    bool _isInGame = false;
    List<CommandTask> _commands = [];

    IssuedTask _currentTask;
    TaskStatus _taskStatus;
    DateTime _sendTaskTime;
    DateTime _failTaskTime;
    int _idx;

    bool get isInGame
    {
        return _isInGame;
    }

    GameClient(GameServer server, WebSocket socket, this._idx)
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
                    _server.sendReadyState();
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
        _isInGame = false;
        _isReady = false;
        _taskStatus = null;
        _currentTask = null;
        _sendTaskTime = null;
        _failTaskTime = null;
    }

    gameOver()
    {
        reset();
        _sendJSONMessage("gameOver", true);
    }

    void _completeTask()
    {
        _server.completeTask(_currentTask);
        _taskStatus = TaskStatus.complete;
        _currentTask = null;
        _failTaskTime = null;
        _sendJSONMessage("taskComplete", "Like a glove!");
    }

    void _sendTask()
    {
        // a null task means we are done with tasks (but game may not be over as other clients may be still completing tasks)
        if(_currentTask == null)
        {
            _sendJSONMessage("newTask", 
            {
                "message":"I'm done with you. Listen to your colleagues.",
                "expiry":0
            });
        }
        else
        {
            _sendJSONMessage("newTask", _currentTask.serialize());
        }
        
    }

    void _failTask()
    {
        if(_currentTask.task.doesAutocomplete())
        {
            _server.completeTask(_currentTask);
        }
        _taskStatus = TaskStatus.failed;
        _currentTask = null;
        _sendJSONMessage("taskFail", "You're dead to me!" );
    }

    get isReady => _isReady;

    IssuedTask get currentTask => _currentTask;
    
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

    startGame()
    {
        _isInGame = _isReady;
        _taskStatus = TaskStatus.complete;
        _currentTask = null;

        _assignTask(false);
    }

    void _assignTask(bool delaySend)
    {
        assert(_sendTaskTime == null);
        _currentTask = _server.getNextTask(this);
        //print("ASSIGNED TASK $_currentTask to $_idx");
        _taskStatus = _currentTask == null ? TaskStatus.noMore : TaskStatus.inProgress;
        _sendTaskTime = null;
        if(delaySend)
        {
            _sendTaskTime = new DateTime.now().add(timeBetweenTasks);
        }
        else
        {
            _sendTask();
        }
        
        if(_currentTask != null)
        {
            int expiry = _currentTask.expires;
            _failTaskTime = new DateTime.now().add(new Duration(seconds:delaySend ? expiry + timeBetweenTasks.inSeconds : expiry));
        }
    }

    void advanceGame()
    {
        if(!_isInGame || !_isReady)
        {
            print("Attempted to advance when we're not in ready or in game.");
            return;
        }
        
        DateTime now = new DateTime.now();
        switch(_taskStatus)
        {
            case TaskStatus.inProgress:
            case TaskStatus.noMore:
                if(_sendTaskTime != null && _sendTaskTime.isBefore(now))
                {
                    _sendTaskTime = null;
                    _sendTask();
                }
                if(_failTaskTime != null && _failTaskTime.isBefore(now))
                {
                    _failTaskTime = null;
                    _failTask();
                }
                break;
            case TaskStatus.complete:
            case TaskStatus.failed:
                if(_currentTask == null)
                {
                    _assignTask(true);
                }
                break;
        }
    }

    bool performTask(String type, int value)
    {
        if(_currentTask == null)
        {
            return false;
        }
        
        if(_currentTask.task.taskType() == type && _currentTask.value == value)
        {
            _completeTask();
            return true;
        }

        return false;
    }

    set readyList(List<bool> readyPlayers)
    {
        _sendJSONMessage("playerList", readyPlayers);
    }

    void _sendJSONMessage<T>(String msg, T payload)
    {
        var message = json.encode({
            "message": msg,
            "payload": payload,
            "gameActive":_server._inGame,
            "inGame":_isInGame
        });
        _socket.add(message);
    }

}

class GameServer
{
    FlutterTask _flutterTask;
    TaskList _taskList;
    List<GameClient> _clients = new List<GameClient>();
    bool _inGame = false;
    bool _isHotReloading = false;
    bool _waitingToHotReload = false;
    String _template;
    int _lineOfInterest = 0;
    UpdateCodeCallback onUpdateCode;

    Map<String, CommandTask> _completedTasks;

    GameServer(this._flutterTask, this._template)
    {
        SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
        SchedulerBinding.instance.scheduleForcedFrame();
        connect();
    }

    void beginFrame(Duration timeStamp) 
	{
        if(_inGame)
        {
            gameLoop();
        }

        if(!SchedulerBinding.instance.framesEnabled)
        {
            print("TEST MESSAGE: FRAMES WON'T FIRE");
        }
        SchedulerBinding.instance.scheduleFrameCallback(beginFrame, rescheduling:true);
        SchedulerBinding.instance.scheduleForcedFrame();
    }

    void connect()
    {
        // HttpServer.bind("10.76.253.124", 8080)
        //String address = "192.168.1.156";
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
        sendReadyState();
    }

    sendReadyState()
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

    int get readyCount
    {
        return _clients.fold<int>(0, 
            (int count, GameClient client) 
            { 
                if(client.isReady)
                {
                    count++;
                }
                return count; 
            });
    }

    onClientStartChanged(GameClient client)
    {
        int numClientsReady = readyCount;

        if(numClientsReady < 2)
        {
            print("Received start, but less than two clients are ready.");
            return;
        }
        else if(_inGame)
        {
            print("Received start, but already in an active game.");
            return;
        }

        // Build the full list.
        _taskList = new TaskList();
        List<CommandTask> taskTypes = new List<CommandTask>.from(_taskList.toAssign);
        _completedTasks = new Map<String, CommandTask>();
        
        // Todo: change back to this logic.
        int perClient = (taskTypes.length/max(1,numClientsReady)).ceil();
        //int perClient = 2;
        hotReload();

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

            gc.startGame();
        }
        _inGame = true;
    }

    onClientInput(Map input)
    {
        var inputType = input['type'];
        var inputValue = input['value'];
        if(inputType is String && inputValue is int)
        {
            for(var gc in _clients)
            {
                if(gc.performTask(inputType, inputValue))
                {
                    break;
                }
            }
        }
    }

    void gameLoop()
    {
        bool someoneHasTask = false;
        int playersLeft = 0;
        for(GameClient gc in _clients)
        {
            if(!gc.isInGame)
            {
                continue;
            }
            gc.advanceGame();

            if(gc.currentTask != null)
            {
                someoneHasTask = true;
            }
            playersLeft++;
        }

        if(playersLeft < 2 || (!someoneHasTask && _taskList.isEmpty))
        {
            onGameOver();
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

        sendReadyState();
    }

    void completeTask(IssuedTask it)
    {
        it.task.complete(it.value, _template);
        if(it.task.hasLineOfInterest)
        {
            _lineOfInterest = it.task.lineOfInterest;
        }
        _completedTasks[it.task.taskType()] = it.task;
        hotReload();
    }

    void hotReload()
    {
        if(_isHotReloading)
        {
            _waitingToHotReload = true;
            return;
        }

        String code = _template.toString();
        
        _completedTasks.forEach((String key, CommandTask task)
        {
            code = task.apply(code);
        });

        _isHotReloading = true;

        _flutterTask.write("/lib/main.dart", code).then((ok)
		{
            _flutterTask.hotReload().then((ok)
            {
                onUpdateCode(code, _lineOfInterest ?? 0);
                _isHotReloading = false;
                if(_waitingToHotReload)
                {
                    _waitingToHotReload = false;
                    hotReload();
                }
            });
        });
    }

    IssuedTask getNextTask(GameClient client)
    {
        return _taskList.nextTask(client.commands);
    }

    _handleWebSocket(WebSocket socket)
    {
        print("ADD WEBCLIENT! ${this._clients.length}");
        GameClient client = new GameClient(this, socket, _clients.length);
        _clients.add(client);
        sendReadyState();
    }
}