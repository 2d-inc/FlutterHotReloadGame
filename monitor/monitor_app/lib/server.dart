import "dart:io";
import 'dart:math';
import "dart:ui";

import "package:flutter/scheduler.dart";

import 'flutter_task.dart';
import "high_scores.dart";
import "tasks/command_tasks.dart";
import "tasks/task_list.dart";

import "client.dart";

/// The Controls are divided into three categories. The client needs to know which one is which
/// in order to display the information correctly and display the right widget in the app.
enum CommandTypes
{ 
    slider, radial, binary 
}

/// The status of a given task.
enum TaskStatus 
{ 
    complete, inProgress, failed, noMore 
}

/// Some internal callbacks that are set by the [Monitor]. This allows the object to respond to some Server events.
typedef void UpdateCodeCallback(String code, int line);
typedef void OnTaskIssuedCallback(IssuedTask task, DateTime failTime);
typedef void OnTaskCompletedCallback(IssuedTask task, DateTime failTime, String message);
typedef void OnScoreIncCallback(int amount);
typedef void ProgressChangeCallback(double value);

class GameServer
{
    static const double minMultiplier = 1.0;
    static const double maxMultiplier = 6.0;
    static const int taskScore = 2000;
    static const int mistakePenalty = -2000;
    static const int LifeMultiplier = 6000;

    FlutterTask _flutterTask;
    TaskList _taskList;
    List<GameClient> _clients = new List<GameClient>();
    bool _inGame = false;
    bool _isHotReloading = false;
    bool _waitingToHotReload = false;
    String _originalTemplate;
    String _template;
    int _lineOfInterest = 0;
    UpdateCodeCallback onUpdateCode;
    OnTaskIssuedCallback onTaskIssued;
    OnTaskCompletedCallback onTaskCompleted;
    OnScoreIncCallback onScoreIncreased;
    VoidCallback onGameOver;
    VoidCallback onGameStarted;
    VoidCallback onLivesUpdated;
    VoidCallback onScoreChanged;
    VoidCallback onIssuingFinalValues;
    ProgressChangeCallback onProgressChanged;

    int _lives = 0;
    int _score = 0;
    HighScore _highScore;
    bool _gotInitials = false;
    double _progress = 0.0;
    bool _isIssuingFinalValues = false;
    DateTime _waitForInstructionsTime;

    Map<String, CommandTask> _completedTasks;
    HighScores _highScores;

    /// When the game server is created by the [Monitor], a [FlutterTask] is registered. 
    /// This task reads (if present) a JSON file in the root directory containing the Highscores that 
    /// had been saved in previous games. This allows the [Monitor] to show older results while the Server 
    /// waits for players to start a new game.
    GameServer(FlutterTask flutterTask, this._originalTemplate)
    {
        this.flutterTask = flutterTask;
        _highScores = new HighScores(flutterTask);
        
        SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
        SchedulerBinding.instance.scheduleForcedFrame();

        listen();
    }

    /// Upon creation, this callback is registered onto the Scheduler.
    /// This way the server reacts promptly to any I/O event, and the game loop smoothly.
    void beginFrame(Duration timeStamp) 
	{
        /// Wait for the [_inGame] flag to be raised, so that the loop can start.
        if(_inGame)
        {
            gameLoop();
        }

        if(!SchedulerBinding.instance.framesEnabled)
        {
            print("TEST MESSAGE: FRAMES WON'T FIRE");
        }
        /// Reschedule this function.
        SchedulerBinding.instance.scheduleFrameCallback(beginFrame, rescheduling:true);
        SchedulerBinding.instance.scheduleForcedFrame();
    }

    /// Bind the [ServerSocket] with any IPv4 address: any adequate [GameClient] can thus be connected with this entity
    /// and registered as locally available.
    /// When a new client connects, it is registered locally, and the server sends to each one an updated list of players.
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

    /// When a client is disconnected, it needs to removed from the set, and an updated list is sent over to the remaining clients.
    onClientDisconnected(GameClient client)
    {
        print("CLIENT DISCONNECTED.");
        this._clients.remove(client);
        sendReadyState();
    }

    /// Evaluate how many clients are still connected.
    /// For the non-zombie ones that are not playing, send the current set.
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
            // Don't spam possible zombie sockets or in-game clients.
            if(!gc.isReal || gc.isInGame)
            {
                continue;
            }

            gc.readyList = readyList;
        }
    }

    /// Updates the local score with a new value.
    /// If a dopamine effect has been registered onto this server, send the score delta so that the app can display it on the screen.
    /// Update the main window with the new value, and send the score to all the connected clients.
    void _setScore(int score, {bool callIncreased = true})
    {
		if(score == _score)
		{
			return;
		}

        int lastScore = _score;
        _score = max(0, score);
        if(callIncreased && onScoreIncreased != null)
        {
            onScoreIncreased(_score - lastScore);
        }
        if(onScoreChanged != null)
        {
            onScoreChanged();
        }

        for(var gc in _clients)
        {
            gc.score = score;
        }
    }

    /// Update the local variable, the main [Monitor] and all the clients with the new value.
    void _setLives(int lives)
    {
		if(_lives == lives)
		{
			return;
		}
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

    /// Get the initials for the current team when a game has been won.
    /// The special String value "000" is filtered out, otherwise the JSON file is updated.
    void setInitials(String initials)
    {
        if(_gotInitials || initials == null)
        {
            return;
        }
        initials = initials.toUpperCase();
        
        if(_highScore != null)
        {
            if(initials == "000")
            {
                _highScores.remove(_highScore);
            }
            else
            {
                _highScore.name = initials;
            }
            _highScores.save();
        }

        _gotInitials = true;

        for(var gc in _clients)
        {
            gc.sendGotInitials(initials);
        }

        onScoreChanged();
    }

    /// Get ready to start a game!
    /// If any one player is set to "READY" but hasn't pressed "START", the game will wait for everyone.
    /// Only one game can run at the same time.
    onClientStartChanged(GameClient client)
    {
        if(!allReadyToStart)
        {
            return;
        }

        if(onProgressChanged != null)
        {
            onProgressChanged(_progress);
        }

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

        /// Upone start, reset some parameters, assign the correct number of lives, and start.
		print("Starting game!");
        _gotInitials = false;
		_isIssuingFinalValues = false;
        _progress = 0.0;
        _highScore = null;
        _setLives(5);
        _setScore(0, callIncreased: false);
        _template = _originalTemplate;

        // Build the full list.
        _taskList = new TaskList(numClientsReady);
        List<CommandTask> taskTypes = new List<CommandTask>.from(_taskList.allTasks);
        _completedTasks = new Map<String, CommandTask>();
        
        int perClient = min(5, (taskTypes.length/max(1,numClientsReady)).ceil());

        print("PER CLIENT $perClient");
        hotReload();

        _inGame = true;

        /// tell every client the game has started and what their commands are...
        /// build list of command id to possible values
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
            
            for(CommandTask task in tasksForClient)
            {
                task.isPlayable = true;
            }
            gc.startGame(tasksForClient);   
        }
        _waitForInstructionsTime = new DateTime.now().add(new Duration(seconds:8));
        _taskList.setNonPlayableToFinal();
        onGameStarted();
    }

    /// Ping callback to make sure that no connected client is hung and not responding anymore.
    void onHello(GameClient client)
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

    /// Whenever a button is pressed, or a slider is set on the client app, the value is relied to the server, 
    /// which reacts accordingly: first it sets the task value and reloads the connected emulator with the input value.
    /// Then it attempts to perform the task in the context of the game (determine if the task was one someone requested).
    /// If this input wasn't requested by anyone in the game, it weas the wrong value, and the game will register a negative
    /// score.
    void onClientInput(GameClient client, Map input)
    {
        var inputType = input['type'];
        var inputValue = input['value'];
        if(inputType is String && inputValue is int)
        {
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
            for(var gc in _clients)
            {
                if(gc.performTask(client, inputType, inputValue))
                {
                    wasCompletion = true;
                    break;
                }
            }

            if(!wasCompletion)
            {
                _setScore(_score+mistakePenalty);
                client.notifyContribution(mistakePenalty);
            }
        }
    }

    /// The core of the game, where the server advances the game for each client, and makes sure that the current
    /// game isnt' over yet. If it is, let all the players know.
    void gameLoop()
    {
        if(_waitForInstructionsTime.isAfter(new DateTime.now()))
        {
            // waiting for instructions
            return;
        }
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

    /// When a game is over, register all the relevant stats and send them to each participant.
    void _onGameOver(bool isDead, {bool saveScore = true})
    {
        _inGame = false;
        bool isHighScore = saveScore && _score > 0 && _highScores.isTopTen(_score + max(0, _lives) * LifeMultiplier);
		_highScore = _highScores.addScore("???", _score + max(0, _lives) * LifeMultiplier, playerCount);
        print("GAME OVER! $isHighScore");
        for(var gc in _clients)
        {
            gc.gameOver(isDead, isHighScore, _score, LifeMultiplier, _highScore.idx+1, max(0,_lives), progress);
        }
        onGameOver();

        sendReadyState();
    }

    /// This functions is associated with the restart button in the main window. Whenever a game needs to be interrupted
    /// 'in-fieri', just press the button and force everyone out.
    restartGame()
    {
        _onGameOver(false, saveScore:false);
    }

    // N.B. this function is only for testing.
    void forceCompleteTask(IssuedTask it)
    {
        CommandTask task = _taskList.setTaskValue(it.task.taskType(), it.value);
        if(task != null)
        {
            task.complete(it.value, _template);
            if(task.hasLineOfInterest)
            {
                _lineOfInterest = task.lineOfInterest;
            }
            _completedTasks[task.taskType()] = task;

            hotReload();
        }
    }

    /// Upon a task completion, evaluate the score for it, advance the app and update all the necessary values.    
    void completeTask(GameClient owner, GameClient completer, IssuedTask it, Duration remaining)
    {
        // Assign score.        
        double factor = (remaining.inSeconds/it.expires).clamp(0.0, 1.0);
        
        double multiplier = lerpDouble(minMultiplier, maxMultiplier, factor);
        int scoreInc = (taskScore * multiplier).floor();
        _setScore(_score+scoreInc);
        if(completer != null)
        {
            completer.notifyContribution(scoreInc);
        }
        // Advance app.
        _template = _taskList.completeTask(_template);

        bool tasksInFinal = _taskList.isIssuingFinalValues;
        /// If this game is almost complete, show a Dopamine effect urge players that they're almost finished.
        if(tasksInFinal && tasksInFinal != _isIssuingFinalValues)
        {
            _isIssuingFinalValues = tasksInFinal;
            _taskList.prepForFinals();
            onIssuingFinalValues();
        }
        
        double progress = _taskList.progress;
        if(_progress != progress)
        {
            _progress = progress;
            if(onProgressChanged != null)
            {
                onProgressChanged(_progress);
            }
        }
    }

    /// When a task fails (time runs out), the team loses a life.
    void failTask(IssuedTask it)
    {
        _setLives(_lives-1);
    }

    /// The server issues a [FlutterTask] command to reload the code on the Simulator/Emulator that's supposed to be running 
    /// in the foreground. The Simulator App will reflect the change that's been caused by a client's input by using Flutter's hot reload.
    void hotReload()
    {
        if(_isHotReloading || _flutterTask == null)
        {
            _waitingToHotReload = true;
            return;
        }

        String code = _taskList.transformCode(_template.toString());

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

    /// Evaluate which is the next task that a client can get.
    // A client is allowed to receive one of its own tasks, but the server first makes sure to exclude any currently assigned tasks.
    IssuedTask getNextTask(GameClient client)
    {
        List<CommandTask> avoid = new List<CommandTask>();
        for(GameClient gc in _clients)
        {
            if(gc.currentTask != null)
            {
                avoid.add(gc.currentTask.task);
            }
        }    
        return _taskList.nextTask(avoid, timeMultiplier:lerpDouble(1.0, 2.0, min(1.0, (playerCount-2.0)/6)), lowerChance:client.commands);
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

    bool get inGame => _inGame;
    FlutterTask get flutterTask => _flutterTask;
    HighScore get highScore => _highScore;
    HighScores get highScores => _highScores;
    int get lives => _lives;

    int get playerCount
    {
        return _clients.fold<int>(0, 
            (int count, GameClient client) 
            { 
                if(client.isInGame)
                {
                    count++;
                }
                return count; 
            });
    }

    double get progress => _progress;

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

    int get score => _score;

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
}