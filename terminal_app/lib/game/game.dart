import 'dart:async';
import "dart:convert";
import "dart:io";
import 'dart:math';

import "package:audioplayers/audioplayer.dart";
import "package:crypto/crypto.dart";
import 'package:flutter/services.dart';
import "package:path_provider/path_provider.dart";
import "package:uuid/uuid.dart";

import "delegates/audio_player_delegate.dart";
import "delegates/dopamine_delegate.dart";
import "delegates/socket_delegate.dart";
import "socket_client.dart";
import "blocs/connection_bloc.dart";
import "blocs/game_stats_bloc.dart";
import "blocs/in_game_bloc.dart";
import "blocs/scene_bloc.dart";
import "widgets/character_scene/terminal_scene.dart";

class Game implements SocketDelegate, AudioPlayerDelegate, DopamineDelegate
{
	static const int statsDropSeconds = 15;
    static const String _waitingMessage = "Waiting for 2-4 players!";

    final InGameBloc inGameBloc;
    final GameStatsBloc gameStatsBloc;
    final GameConnectionBloc gameConnectionBloc;
    final SceneBloc sceneBloc;

    SocketClient _client;
    SocketMessageCallback onMessage;
    SocketReadyCallback onReady;

    DopamineScoreCallback onScored;
    DopamineLifeLostCallback onLifeLost;

    Timer _highscoreTimer;
    List<AudioPlayer> _audioPlayers = new List<AudioPlayer>();
    
    Game({InGameBloc igb, GameStatsBloc gsb, GameConnectionBloc gcb, SceneBloc sb}) :
        inGameBloc = igb ?? new InGameBloc(),
        gameStatsBloc = gsb ?? new GameStatsBloc(),
        gameConnectionBloc = gcb ?? new GameConnectionBloc(),
        sceneBloc = sb ?? new SceneBloc()
    {
        onMessage = onSocketMessage;
        onReady = handleReady;
        initSocketClient(new Uuid().v4());
        resetSceneMessage();
    }

    initSocketClient(String uniqueId)
	{
        onReady = handleReady;
        onMessage = onSocketMessage;
        _client = new SocketClient(this, uniqueId);
		_client.onConnectionChanged = ()
		{
            gameConnectionBloc.setLast(isConnected: _client.isConnected);
		};
	}

    bool handleReady()
	{
		bool readyState = !gameConnectionBloc.last.isReady;
        gameConnectionBloc.setLast(isReady: readyState);
		return readyState;
	}


    void issueCommand(String taskType, int value)
	{
		if(_client == null)
		{
			return;
		}
		print("SEND COMMAND $taskType $value");
		_client.sendCommand(taskType, value);
	}
       
    dispose()
    {
        if(_client != null)
        {
            _client.dispose();
        }
    }

    onSocketMessage(jsonMsg)
    {
        var payload = jsonMsg['payload'];
        String msg = jsonMsg['message'];

        var gameActive = jsonMsg['gameActive'];
        var inGame = jsonMsg['inGame'];
        var isClientReady = jsonMsg['isReady'];
        var didClientMarkStart = jsonMsg['markedStart'];
        
        if(gameActive is bool && inGame is bool)
        {
            setGameStatus(gameActive, inGame, isClientReady, didClientMarkStart);
        }
        
        switch(msg)
        {
            case "talk":
                onTalk(payload as String);
                break;
            case "commandsList":
                onGameStart(payload as List);
                break;
            case "gameOver":
                var isHighScore = payload["highscore"];
                var didDie = payload["died"];
                var score = payload["score"];
                var lifeScore = payload["lifeScore"];
                var rank = payload["rank"];
                var lives = payload["lives"];
                var progress = payload["progress"];
                if(isHighScore is bool && didDie is bool && score is int && lifeScore is int && rank is int && lives is int && progress is double)
                {
                    gameOver(isHighScore, didDie, score, lifeScore, rank, lives, progress);
                }
                break;
            case "newTask":
                onNewTask(payload as Map);
                break;
            case "playerList":
                List<bool> boolList = [];
                /// Dart Strong Mode requires type safety.
                for(var b in payload) 
                {
                    if(b is bool) boolList.add(b);
                }
                onPlayersList(boolList);
                break;
            case "contribution":
                onScoreContribution(payload as int);
                break;
            case "taskFail":
                onTaskFail(payload as String);
                break;
            case "taskComplete":
                onTaskComplete(payload as String);
                break;
            case "teamLives":
                onLivesChanged(payload as int);
                break;
            case "score":
                onScoreChanged(payload as int);
                break;
            case "initials":
                onServerInitials(payload as String);
                break;
            default:
                print("UNKNOWN MESSAGE: $jsonMsg");
                break;
        }
    }

    void setGameStatus(bool isServerInGame, bool isClientInGame, bool doesServerThinkImReady, bool doesServerThinkStart)
	{
        gameConnectionBloc.setLast(
            isReady: doesServerThinkImReady, 
            markedStart: doesServerThinkStart, 
            canBeReady: !isServerInGame // we can only mark ready if the server isn't already in a game.
        );
        if(!inGameBloc.last.isOver && connection.isPlaying && !isClientInGame)
        {
            //_backToLobby();
            showGameOver(false, false);
        }
	}

	void onTalk(String msg)
	{
		playAudio("assets/audio/new_command.wav");

        sceneBloc.setLast(sceneMessage: msg);
	}

    void onGameStart(List commands)
    {
        if(!connection.isReady)
		{
			return;
		}
		if(connection.isPlaying)
		{
			return;
		}

        gameConnectionBloc.setLast(isPlaying: true);
        inGameBloc.setLast(gridDescription: commands, isOver: false, hasWon: false);
        
        // Manually reset these fields.
        sceneBloc.nullifyParams(true, true, true);
        sceneBloc.setLast(
			sceneState: TerminalSceneState.BossOnly,
            sceneCharacterIndex: new Random().nextInt(4)
        );
        gameStatsBloc.setLast(initials: "");
        print("PLAYING AND SETTING CHARACTER TO ${sceneBloc.last.sceneCharacterIndex}");
    }

    void gameOver(bool isHighScore, bool didDie, int score, int lifeScore, int rank, int lives, double progress)
	{
		showGameOver(isHighScore, didDie);
        inGameBloc.setLast(showStats: true);
        gameStatsBloc.setLast(
            score: max(score, 0),
            lifeScore: lifeScore,
            rank: rank,
            progress: progress,
            lives: max(0, lives),
            time: new DateTime.now().add(const Duration(seconds: 1))
        );

		_highscoreTimer = new Timer(const Duration(seconds:statsDropSeconds), ()
		{
            inGameBloc.setLast(showStats: false);
		});
	}

    void showGameOver(bool isHighScore, bool didDie)
	{
		if(_highscoreTimer != null)
		{
			_highscoreTimer.cancel();
		}
        inGameBloc.setLast(hasWon: isHighScore, isOver: true);
        sceneBloc.nullifyParams(true, true, true);
        /// Update the stream with the nulled values.
        sceneBloc.setLast();
	}


	void onNewTask(Map task)
	{
		String msg = task['message'] as String;
		int time = task['expiry'] as int;
		playAudio("assets/audio/new_command.wav");

        bool isTimeNull = time == 0;
        DateTime start;
        DateTime end;
        if(isTimeNull)
        {
            sceneBloc.nullifyParams(false, isTimeNull, isTimeNull);
        }
        else
        {
            start = new DateTime.now();
            end = new DateTime.now().add(new Duration(seconds: time));
        }
        sceneBloc.setLast(sceneMessage: msg, commandStartTime: start, commandEndTime: end,sceneCharacterIndex: new Random().nextInt(4));
	}


	onPlayersList(List<bool> readyList)
	{
        gameConnectionBloc.setLast(arePlayersReady: readyList);
        resetSceneMessage();
	}

	void onScoreContribution(int score)
	{
		if(onScored != null)
		{
			onScored(score);
		}
		if(score < 0)
		{
			playAudio("assets/audio/fail.wav");
		}
		else
		{
			playAudio("assets/audio/success.wav");
		}
	}
	
    void onTaskFail(String msg)
	{
	    sceneBloc.setLast(sceneMessage: msg);
	}

	void onTaskComplete(String msg)
	{
        sceneBloc.nullifyParams(false, true, true);
        sceneBloc.setLast(sceneMessage: msg);
	}

    void onLivesChanged(int value)
	{
        int l = gameStatsBloc.lives;
		if(l != value)
		{
			if(value < l)
			{
				playAudio("assets/audio/life_lost.wav");
                if(onLifeLost != null)
                {
                    onLifeLost();
                }
			}
            gameStatsBloc.setLast(lives: value);
		}
	}
    
    void onScoreChanged(int value)
	{
        if(gameStatsBloc.score != value)
        {
            gameStatsBloc.setLast(score: value);
        }
	}

	void onServerInitials(String initials)
	{
        if(gameStatsBloc.initials != initials)
        {
            gameStatsBloc.setLast(initials: initials);
        }
	}

    resetSceneMessage()
	{
		if(connection.isPlaying)
		{
			return;
		}
		String message = connection.arePlayersReady.fold<int>(0, (int count, bool value) { if(value) { count++; } return count;} ) >= 2 ? "Come on, we've got a deadline to meet!" : _waitingMessage;
		if(message != sceneBloc.last.sceneMessage)
		{
			sceneBloc.setLast(sceneMessage: message);
		}
	}

    backToLobby()
    {
        inGameBloc.setLast(gridDescription: [], isOver: false);
        String message = connection.arePlayersReady.fold<int>(0, (int count, bool value) { if(value) { count++; } return count;} ) >= 2 ? "Come on, we've got a deadline to meet!" : _waitingMessage;
        sceneBloc.setLast(sceneMessage: message, sceneState: TerminalSceneState.All);
        gameConnectionBloc.setLast(isReady: false, markedStart: false, isPlaying: false);
    }

	Future<String> _loadFile(String from) async 
	{
		final dir = await getApplicationDocumentsDirectory();
		ByteData data = await rootBundle.load(from);
		var digest = sha1.convert(utf8.encode(from));	
		String filename = "${dir.path}/${digest.toString()}";
		final file = new File(filename);
		if(await file.exists())
		{
			return filename;
		}
		
		await file.writeAsBytes(data.buffer.asUint8List().toList());
		return filename;
	}
    
    void playAudio(String url)
	{
		_loadFile(url).then((String filename)
		{
			AudioPlayer player = new AudioPlayer();
			player.completionHandler = ()
			{
				_audioPlayers.remove(player);
			};
			_audioPlayers.add(player);
			player.play(filename, isLocal: true);
		});
	}


	set isReady(bool isIt)
	{
        gameConnectionBloc.setLast(isReady: isIt);
	}

    SocketClient get client => _client;
    ConnectionInfo get connection => gameConnectionBloc.last;
}