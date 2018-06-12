import "dart:io";
import 'dart:math';
import "dart:ui";

import "package:flutter/scheduler.dart";

import 'flutter_task.dart';
import "high_scores.dart";
import "tasks/command_tasks.dart";
import "tasks/task_list.dart";

import "client.dart";

enum CommandTypes 
{ 
    slider, radial, binary 
}

enum TaskStatus 
{ 
    complete, inProgress, failed, noMore 
}

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

    GameServer(FlutterTask flutterTask, this._originalTemplate)
    {
        this.flutterTask = flutterTask;
        _highScores = new HighScores(flutterTask);
        
        SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
        SchedulerBinding.instance.scheduleForcedFrame();

        listen();
    }

    int get lives => _lives;
    int get score => _score;
    bool get inGame => _inGame;
    double get progress => _progress;
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
            // Don't spam possible zombie sockets or in-game clients.
            if(!gc.isReal || gc.isInGame)
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

    void onClientInput(GameClient client, Map input)
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

    
        return _taskList.nextTask(avoid, timeMultiplier:lerpDouble(1.0, 2.0, min(1.0, (playerCount-2.0)/6)), lowerChance:client.commands);
    }
}