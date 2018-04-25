import "dart:io";
import "dart:convert";
import "dart:async";
import 'dart:math';
import "tasks/task_list.dart";
import "tasks/icon_tasks.dart";
import "high_scores.dart";
import "tasks/command_tasks.dart";
import "package:flutter/scheduler.dart";
import 'flutter_task.dart';
import "dart:ui";

enum CommandTypes { slider, radial, binary }
enum TaskStatus { complete, inProgress, failed, noMore }

typedef void UpdateCodeCallback(String code, int line);
typedef void OnTaskIssuedCallback(IssuedTask task, DateTime failTime);
typedef void OnTaskCompletedCallback(IssuedTask task, DateTime failTime, String message);

List<String> completedMessages = <String>
[
    "Nicely done!",
    "Looking good!",
    "Like a glove!",
    "Exactly what I wanted!",
    "You're a star!",
    "Home run!",
    "You're my favorite!",
    "Keep it up!"
];

List<String> failedMessages = <String>
[
    "You're dead to me!",
    "Get out of my sight!",
    "Look at what you've done!",
    "Are you even listening to me?!",
    "Hello? Hello?! Anybody home?!",
    "This is a disgrace."
];

const double minMultiplier = 1.0;
const double maxMultiplier = 5.0;
const int taskScore = 1000;
const int mistakePenalty = -1500;

class GameClient
{
    static const Duration timeBetweenTasks = const Duration(seconds: 2);
    Socket _socket;
    GameServer _server;

    bool _isReady = false;
    bool _isInGame = false;
    bool _markedStart = false;
    List<CommandTask> _commands = [];

    IssuedTask _currentTask;
    TaskStatus _taskStatus;
    DateTime _sendTaskTime;
    DateTime _failTaskTime;
    String _name;
    DateTime _lastHello = new DateTime.now();
    int _idx;
    String _data;

    int _lives = 0;
    
    int get lives => _lives;
    bool get isInGame => _isInGame;
    bool get markedStart => _markedStart;
    String get name => _name;

    Duration get lastHello
    {
        return _lastHello.difference(DateTime.now());
    }

    bool get isReal
    {
        return _name != null;
    }

    GameClient(GameServer server, Socket socket, this._idx)
    {
        _data = "";
        _socket = socket;
        _server = server;
        _socket.transform(utf8.decoder).listen(_dataReceived, onDone: _onDisconnected);
    }

    disconnect()
    {
        print("CLOSING SOCKET $_name");
        _socket.close();
    }

    _onDisconnected()
    {
        print("${this.runtimeType} disconnected!");
        _server.onClientDisconnected(this);
    }

    void _jsonReceived(jsonMsg)
    {
        String msg = jsonMsg['message'];
            
        //print("Just received ====:\n $message");
        switch(msg)
        {
            case "ready":
                _isReady = jsonMsg['payload'];
                if(!_isReady)
                {
                    _markedStart = false;
                }
                print("PLAYER READY? $_isReady");
                _server.sendReadyState();
                break;
            case "startGame":
                print("READY TO START");
                _markedStart = true;
                _server.sendReadyState();
                _server.onClientStartChanged(this);
                break;
            case "clientInput":
                var payload = jsonMsg['payload'];
                _server.onClientInput(payload);
                break;
            case "hi":
                _lastHello = new DateTime.now();
                String payload = jsonMsg['payload'];
                _name = payload;
                _server.onHello(this);
                break;
            case "initials":
                _server.setInitials(jsonMsg['payload']);
                break;
            default:
                print("MESSAGE: $jsonMsg");
                break;
        }
    }

    void _dataReceived(String message)
    {
        _data += message;
        while(true)
        {
            int idx = _data.indexOf("\n");
            if(idx == -1)
            {
                return;
            }

            String encodedJson = _data.substring(0, idx);
            try
            {
                var jsonMsg = json.decode(encodedJson);
                _jsonReceived(jsonMsg);
            }
            on FormatException catch(e)
            {
                print("Wrong Message Formatting, not JSON: $encodedJson");
                print(e);
            }
            _data = _data.substring(idx+1);
        }
    }
    
    reset()
    {
        _isInGame = false;
        _isReady = false;
        _markedStart = false;
        _taskStatus = null;
        _currentTask = null;
        _sendTaskTime = null;
        _failTaskTime = null;
    }

    gameOver(bool isDead, bool isHighScore)
    {
        reset();
        _sendJSONMessage("gameOver", {"highscore":isHighScore, "died":isDead});
    }

    void _completeTask()
    {
        String message = completedMessages[new Random().nextInt(completedMessages.length)];

        _server.onTaskCompleted(_currentTask, _failTaskTime, message);
        _server.completeTask(_currentTask, _failTaskTime.difference(DateTime.now()));
        _taskStatus = TaskStatus.complete;
        _currentTask = null;
        _failTaskTime = null;
        _sendJSONMessage("taskComplete", message);
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
        _server.failTask(_currentTask);
        _taskStatus = TaskStatus.failed;
        _currentTask = null;

        _sendJSONMessage("taskFail", failedMessages[new Random().nextInt(failedMessages.length)]);
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

    startGame(List<CommandTask> tasks)
    {
        _markedStart = true;
        _isReady = true;
        _isInGame = true;

        this.commands = tasks;
        _taskStatus = TaskStatus.complete;
        _currentTask = null;

        _assignTask(false);
    }

    waitGame()
    {
        _sendJSONMessage("wait", true);  
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

            _server.onTaskIssued(_currentTask, _failTaskTime);
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
        
        if(_currentTask.task.taskType() == type)
        {
            if(_currentTask.value == value)
            {
                _completeTask();
                return true;
            }
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
            "inGame":_isInGame,
            "isReady":_isReady,
            "markedStart":_markedStart
        });
        _socket.writeln(message);
    }

    set lives(int livesLeft)
    {
        _sendJSONMessage("teamLives", livesLeft);
    }

    set score(int score)
    {
        _sendJSONMessage("score", score);
    }

    sendGotInitials(initials)
    {
        _sendJSONMessage("initials", initials);
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
    OnTaskIssuedCallback onTaskIssued;
    OnTaskCompletedCallback onTaskCompleted;
    VoidCallback onGameOver;
    VoidCallback onGameStarted;
    VoidCallback onLivesUpdated;
    VoidCallback onScoreChanged;
    int _lives = 0;
    int _score = 0;
    HighScore _highScore;
    bool _gotInitials = false;


    Map<String, CommandTask> _completedTasks;
    HighScores _highScores;

    GameServer(FlutterTask flutterTask, this._template)
    {
        this.flutterTask = flutterTask;
        _highScores = new HighScores(flutterTask);
        
        SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
        SchedulerBinding.instance.scheduleForcedFrame();

        // _highScores.addScore("GLR", 123362622);
        // _highScores.addScore("LFR", 835393323);
        // _highScores.addScore("US", 326212636);
        // _highScores.save();
        
        listen();
    }

    int get lives => _lives;
    int get score => _score;
    HighScore get highScore => _highScore;
    HighScores get highScores => _highScores;

    FlutterTask get flutterTask
    {
        return _flutterTask;
    }

    set flutterTask(FlutterTask task)
    {
        _flutterTask = task;
        if(task != null)
        {
            if(_waitingToHotReload)
            {
                _waitingToHotReload = false;
                hotReload();
            }
        }
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

    void listen()
    {
        ServerSocket.bind(InternetAddress.ANY_IP_V4, 8080).then(
            (serverSocket) 
            {
                serverSocket.listen((socket) 
                {
                    GameClient client = new GameClient(this, socket, _clients.length);
                    _clients.add(client);
                    sendReadyState();

                });
        });
    }

    onClientDisconnected(GameClient client)
    {
        print("CLIENT DISCONNECTED.");
        this._clients.remove(client);
        sendReadyState();
    }

    sendReadyState()
    {
        List<bool> readyList = new List();
        for(GameClient gc in _clients)
        {
            // Zombies don't count.
            if(!gc.isReal)
            {
                continue;
            }
            readyList.add(gc.isReady);
        }

        for(var gc in _clients)
        {
            // Don't spam possible zombie sockets.
            if(!gc.isReal)
            {
                continue;
            }

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

    bool get allReadyToStart
    {
        return _clients.fold<bool>(readyCount >= 2, 
            (bool currentlyReady, GameClient client) 
            { 
                if(client.isReady && !client.markedStart)
                {
                    currentlyReady = false;
                }
                return currentlyReady; 
            });
    }

    void _setScore(int score)
    {
        _score = max(0, score);
        if(onScoreChanged != null)
        {
            onScoreChanged();
        }

        for(var gc in _clients)
        {
            gc.score = score;
        }
    }

    void _setLives(int lives)
    {
        _lives = lives;
        if(onLivesUpdated != null)
        {
            onLivesUpdated();
        }

        for(var gc in _clients)
        {
            gc.lives = lives;
        }
    }

    void setInitials(String initials)
    {
        if(_gotInitials || initials == null)
        {
            return;
        }
        initials = initials.toUpperCase();
        
        if(_highScore != null)
        {
            _highScore.name = initials;
            _highScores.save();
        }

        _gotInitials = true;

        for(var gc in _clients)
        {
            gc.sendGotInitials(initials);
        }

        onScoreChanged();
    }

    onClientStartChanged(GameClient client)
    {
        if(!allReadyToStart)
        {
            return;
        }
        
        _gotInitials = false;
        _highScore = null;
        _setLives(5);
        _setScore(0);

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
        _taskList = new TaskList(numClientsReady);
        List<CommandTask> taskTypes = new List<CommandTask>.from(_taskList.allTasks);
        _completedTasks = new Map<String, CommandTask>();
        
        // Todo: change back to this logic.
        int perClient = (taskTypes.length/max(1,numClientsReady)).ceil();
        //int perClient = 2;
        print("PER CLIENT $perClient");
        hotReload();

        _inGame = true;

        // tell every client the game has started and what their commands are...
        // build list of command id to possible values
        Random rand = new Random();
        for(var gc in _clients)
        {
            if(!gc.isReady)
            {
                gc.waitGame();
                continue;
            }

            List<CommandTask> tasksForClient = new List<CommandTask>();
            while(tasksForClient.length < perClient && taskTypes.length != 0)
            {
                tasksForClient.add(taskTypes.removeAt(rand.nextInt(taskTypes.length)));
            }
            
            gc.startGame(tasksForClient);   
        }
        onGameStarted();
    }

    onHello(GameClient client)
    {
        List<GameClient> impostors = new List<GameClient>();

        for(GameClient gc in _clients)
        {
            if(gc == client)
            {
                continue;
            }

            // Remove clients that already had this name or haven't said hi in a while.
            if(gc.name == client.name || gc.lastHello.inSeconds > 15)
            {
                print("Removing a bad connection ${gc.name} ${gc.lastHello.inSeconds}");
                impostors.add(gc); 
            }
        }

        for(GameClient gc in impostors)
        {
            _clients.remove(gc);
            gc.disconnect();
        }
        sendReadyState();
    }

    onClientInput(Map input)
    {
        var inputType = input['type'];
        var inputValue = input['value'];
        if(inputType is String && inputValue is int)
        {
            // Immediately set the task value and reload.
            CommandTask task = _taskList.setTaskValue(inputType, inputValue);
            if(task != null)
            {
                task.complete(inputValue, _template);
                if(task.hasLineOfInterest)
                {
                    _lineOfInterest = task.lineOfInterest;
                }
                _completedTasks[task.taskType()] = task;

                hotReload();
            }

            bool wasCompletion = false;
            // Attempt to perform the task in the context of the game (determine if the task was one someone requested).
            for(var gc in _clients)
            {
                if(gc.performTask(inputType, inputValue))
                {
                    wasCompletion = true;
                    break;
                }
            }

            if(!wasCompletion)
            {
                _setScore(_score+mistakePenalty);
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

        if(_lives <= 0 || playersLeft < 2)
        {
            _onGameOver(true);
        }
        else if((!someoneHasTask && _taskList.isEmpty))
        {
            _onGameOver(false);
        }
    }

    void _onGameOver(bool isDead, {bool saveScore = true})
    {
        
        _inGame = false;
        bool isHighScore = saveScore && _highScores.isTopTen(_score);
        if(isHighScore)
        {
            _highScore = _highScores.addScore("???", _score);
        }
        print("GAME OVER! $isHighScore");
        for(var gc in _clients)
        {
            gc.gameOver(isDead, isHighScore);
        }
        onGameOver();

        sendReadyState();
    }

    restartGame()
    {
        _onGameOver(false, saveScore:false);
    }

    void completeTask(IssuedTask it, Duration remaining)
    {
        // Assign score.        
        double factor = (remaining.inSeconds/it.expires).clamp(0.0, 1.0);
        
        double multiplier = lerpDouble(minMultiplier, maxMultiplier, factor);
        int scoreInc = (taskScore * multiplier).floor();
        _setScore(_score+scoreInc);

        // Advance app.
        _template = _taskList.completeTask(_template);
    }

    void failTask(IssuedTask it)
    {
        _setLives(_lives-1);
    }

    void hotReload()
    {
        if(_isHotReloading || _flutterTask == null)
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
        // We allow you to receive one of your own tasks, but we make sure to exclude any currently assigned tasks.
        List<CommandTask> avoid = new List<CommandTask>();
        for(GameClient gc in _clients)
        {
            if(gc.currentTask != null)
            {
                avoid.add(gc.currentTask.task);
            }
        }
        return _taskList.nextTask(avoid, lowerChance:client.commands);
    }
}