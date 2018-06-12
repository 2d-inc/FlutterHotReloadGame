import "dart:convert";
import 'dart:io';
import "dart:math";
import "dart:ui";

import "server.dart";
import "tasks/command_tasks.dart";

/// A virtual representation that [GameServer] can use to store data about clients.
/// It has a handle to the [Socket] to also send and receive messages, and it contains all the client game logic,
/// if a player is ready to start, if it's playing, which commands it has, the current task and status,
/// [DateTime]s for when a task has started and is supposed to end, and more.
class GameClient
{
    /// A small delay between a task is completed/failed, and a new one is sent over;
    static const Duration timeBetweenTasks = const Duration(seconds: 2);
    /// If a task is completed successfully, one of these messages is sent over to the Terminal App.
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
    /// If the Client doesn't complete a task before the deadline, 
    /// one of these messages is sent over to the Terminal App.
    static const List<String> failedMessages = <String>
    [
        "You're dead to me!",
        "Get out of my sight!",
        "Look at what you've done!",
        "Are you even listening to me?!",
        "Hello? Hello?! Anybody home?!",
        "This is a disgrace."
    ];

    /// Handle to the [Stream] for communication with the Terminal App.
    Socket _socket;
    /// Keep a reference to the [GameServer] to relay to it any new incoming message from the [Socket].
    GameServer _server;

    /// If a player has pressed the "READY" button on the Terminal, and is thus ready to start a new game.
    bool _isReady = false;
    /// If this player is playing a game.
    bool _isInGame = false;
    /// If this player has pressed the "START" button on Terminal, and is waiting for other players to start as well.
    bool _markedStart = false;
    /// List of Controls assigned to this client.
    List<CommandTask> _commands = [];

    /// The current task, visible on the [TerminalScene] bubble.
    IssuedTask _currentTask;
    /// The task's status.
    TaskStatus _taskStatus;
    /// When the task has been sent, and when the the timer will expire.
    DateTime _sendTaskTime;
    DateTime _failTaskTime;
    /// Client's name, necessary for the [GameServer] to resolve and identify multiple connections from the same device.
    String _name;
    /// A ping checker.
    DateTime _lastHello = new DateTime.now();
    int _idx;
    /// Incoming messages from the [_socket] [Stream].
    String _data;
    /// Lives for the this client.
    int _lives = 0;
    /// The first time a task is sent, all clients will first send a message to the terminal to explain the basics of the game.
    bool _isFirstTask = true;

    GameClient(GameServer server, Socket socket, this._idx)
    {
        _data = "";
        _socket = socket;
        _server = server;
        _socket.transform(utf8.decoder).listen(_dataReceived, onDone: _onDisconnected);
    }

    /// This callback is registered in the constructor; if the stream closes for some reason, 
    /// this callback is used to signal the [GameServer] that the connection is no more.
    _onDisconnected()
    {
        print("${this.runtimeType} disconnected!");
        _server.onClientDisconnected(this);
    }

    /// Close this socket; if for any reason a Terminal has connected twice, the Server knows that 
    /// it can't keep two connections open to the same device, and should remove one of them.
    disconnect()
    {
        print("CLOSING SOCKET $_name");
        _socket.close();
    }

    /// This callback is registered in the constructor; whenever the stream receives a String of data,
    /// this function loops until the message has been processed in its entirety.
    /// If a message is decoded as JSON, it can be directed towards [_jsonReceived], where it is properly handled.
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

    /// Extract the various fields of a JSON message:
    /// - "message" contains the type of the current message;
    /// - "payload" contains the contents for the message.
    /// === JSON MESSAGE EXAMPLE: === 
    /// {
    ///    "message": "ready",
    ///    "payload": true
    /// }
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

    /// Reset all the local fields to their default values.
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

    /// When the [GameServer] has detected that a game has ended (no more lives or tasks completed), every client resets their local state and
    /// signals their respective counterparts that the game is indeed over.
    /// The "gameOver" JSON message that's sent contains all the relevant stats for the game that just ended, such as if the team has won or not,
    /// the score, how many lives were left, etc.
    gameOver(bool isDead, bool isHighScore, int score, int lifeScore, int rank, int lives, double progress)
    {
        reset();
        _sendJSONMessage("gameOver", {"highscore":isHighScore, "died":isDead, "score":score, "lifeScore":lifeScore, "rank":rank, "lives":lives, "progress":progress});
    }

    /// Send over the current new task that the Terminal will show and it's scene.
    /// A null task means we are done with tasks (but game may not be over as other clients may be still completing tasks)
    void _sendTask()
    {
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

    /// When the timer for the curren task is up, let the server and the Terminal know.
    void _failTask()
    {
        _server.failTask(_currentTask);
        _taskStatus = TaskStatus.failed;
        _currentTask = null;

        _sendJSONMessage("taskFail", failedMessages[new Random().nextInt(failedMessages.length)]);
    }

    /// When the client receives a new input from the Terminal, the server evaluates if the input was
    /// the one it was expecting or if it was a wrong value. 
    /// In the first case, a positive score increment, otherwise a negative score is applied.
    void notifyContribution(int scoreInc)
    {
        _sendJSONMessage("contribution", scoreInc);
    }

    /// When a game starts, set all the appropriate status variables and send a message containing the "Tutorial" message.
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

    /// If one or more players are set to "READY" but haven't pressed "START" yet, let the Terminal know that this is the case.
    waitGame()
    {
        _sendJSONMessage("wait", true);  
    }

    /// A new task is assigned to this client. This task is selected by the server from a pool of available tasks.
    /// As the game progresses, the expiry time for every new task will become shorter, and thus the game will become
    /// more difficult.
    /// This'll generally set the [_sendTaskTime] variable to give players some room to breathe between one task and the next,
    /// and let [advanceGame()] take care of actually sending the task.
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

    /// When a task is completed, let the server know that it's done, set the task status and tell the client about it.
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

    /// Game Loop for the current client.
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
                /// If a new task is available, send it over.
                if(_sendTaskTime != null && _sendTaskTime.isBefore(now))
                {
                    _sendTaskTime = null;
                    _sendTask();
                }
                /// If a task has failed, let the client know.
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
            /// Assign a new task.
            case TaskStatus.complete:
            case TaskStatus.failed:
                if(_currentTask == null)
                {
                    _assignTask(true);
                }
                break;
        }
    }

    /// [GameServer.gameLoop()] tries to evaluate if a client input was a task available for this client.
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

    /// Format the JSON message as the Terminal expects it, and send it over the network.
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

    /// Tell this client that initials have been received, and can no longer be input.
    sendGotInitials(initials)
    {
        _sendJSONMessage("initials", initials);
    }
        
    List<CommandTask> get commands => _commands;
    IssuedTask get currentTask => _currentTask;
    bool get isInGame => _isInGame;
    bool get isReady => _isReady;
    bool get isReal => (_name != null);
    Duration get lastHello => _lastHello.difference(DateTime.now());
    int get lives => _lives;
    bool get markedStart => _markedStart;
    String get name => _name;
    TaskStatus get taskStatus => _taskStatus;

    /// Format the list of Controls to be shown in the grid on the Terminal app and send them over.
    set commands(List<CommandTask> commandsList)
    {
        _commands = commandsList;

        List<Map> serializedCommands = new List<Map>();
        for(CommandTask task in _commands)
        {
            serializedCommands.add(task.serialize());
        }
        
        _sendJSONMessage("commandsList", serializedCommands);
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

    /// List of all the players in the game, with their respective statuses.
    set readyList(List<bool> readyPlayers)
    {
		print("SENDING READY $readyPlayers");
        _sendJSONMessage("playerList", readyPlayers);
    }

    set score(int score)
    {
        _sendJSONMessage("score", score);
    }

}