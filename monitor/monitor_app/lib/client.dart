import "dart:convert";
import 'dart:io';
import "dart:math";
import "dart:ui";

import "server.dart";
import "tasks/command_tasks.dart";

class GameClient
{
    static const Duration timeBetweenTasks = const Duration(seconds: 2);
    static const List<String> completedMessages = <String>
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
    static const List<String> failedMessages = <String>
    [
        "You're dead to me!",
        "Get out of my sight!",
        "Look at what you've done!",
        "Are you even listening to me?!",
        "Hello? Hello?! Anybody home?!",
        "This is a disgrace."
    ];

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
    bool _isFirstTask = true;
    
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
                print("CLIENT INPUT $payload");
                _server.onClientInput(this, payload);
                break;
            case "hi":
			
                _lastHello = new DateTime.now();
                String payload = jsonMsg['payload'];
                _name = payload;
				print("GOT HI  $_name");
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
        _isFirstTask = true;
        _isInGame = false;
        _isReady = false;
        _markedStart = false;
        _taskStatus = null;
        _currentTask = null;
        _sendTaskTime = null;
        _failTaskTime = null;
    }

    gameOver(bool isDead, bool isHighScore, int score, int lifeScore, int rank, int lives, double progress)
    {
        reset();
        _sendJSONMessage("gameOver", {"highscore":isHighScore, "died":isDead, "score":score, "lifeScore":lifeScore, "rank":rank, "lives":lives, "progress":progress});
    }

    void _completeTask(GameClient completer)
    {
        String message = completedMessages[new Random().nextInt(completedMessages.length)];

        _server.onTaskCompleted(_currentTask, _failTaskTime, message);
        _server.completeTask(this, completer, _currentTask, _failTaskTime == null ? new Duration(seconds:0) : _failTaskTime.difference(DateTime.now()));
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

    void notifyContribution(int scoreInc)
    {
        _sendJSONMessage("contribution", scoreInc);
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

        _sendJSONMessage("talk", "Listen to my instructions and relay them to your colleagues!");
    }

    waitGame()
    {
        _sendJSONMessage("wait", true);  
    }

    void _assignTask(bool delaySend)
    {
        assert(_sendTaskTime == null);
        _currentTask = _server.getNextTask(this);
		if(_currentTask != null)
		{
        	print("ASSIGNED TASK ${_currentTask.task}");
            int expiry = _currentTask.expires;

            const double minExpiryFactor = 0.5;
            expiry = lerpDouble(expiry, expiry * minExpiryFactor, _server.progress).round();
            if(_isFirstTask)
            {
                expiry = (expiry * 1.5).round();
                _isFirstTask = false;
            }
			_currentTask.expires = expiry;

            _failTaskTime = new DateTime.now().add(new Duration(seconds:delaySend ? expiry + timeBetweenTasks.inSeconds : expiry));

            _server.onTaskIssued(_currentTask, _failTaskTime);
		}
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

                    // Set this to false if you want to test auto-completing tasks.
                    if(true)
                    {
                        _failTask();
                    }
                    else//test auto complete
                    {
						if(_lives > 0 && new Random().nextInt(10) > 6)
						{
							_failTask();
						}
						else
						{
                        	_server.forceCompleteTask(_currentTask);
                        	_completeTask(null);
						}
                    }
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

    bool performTask(GameClient completer, String type, int value)
    {
        if(_currentTask == null)
        {
            return false;
        }
        
        if(_currentTask.task.taskType() == type)
        {
            if(_currentTask.value == value)
            {
                _completeTask(completer);
                return true;
            }
        }

        return false;
    }

    set readyList(List<bool> readyPlayers)
    {
		print("SENDING READY $readyPlayers");
        _sendJSONMessage("playerList", readyPlayers);
    }

    void _sendJSONMessage<T>(String msg, T payload)
    {
        var message = json.encode({
            "message": msg,
            "payload": payload,
            "gameActive":_server.inGame,
            "inGame":_isInGame,
            "isReady":_isReady,
            "markedStart":_markedStart
        });
		print("SENDING MESSAGE $message");
        _socket.writeln(message);
    }

    set lives(int livesLeft)
    {
		if(_lives == livesLeft)
		{
			return;
		}
		_lives = livesLeft;
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