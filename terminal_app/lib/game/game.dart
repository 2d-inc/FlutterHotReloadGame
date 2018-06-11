import 'dart:async';
import "dart:convert";
import "dart:io";
import 'dart:math';

import "package:audioplayers/audioplayer.dart";
import "package:crypto/crypto.dart";
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
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

/// This class is the junction point between the UI and the logic of the app.
/// It implements three delegates:
/// - [SocketDelegate] to manage I/O with the server;
/// - [AudioPlayerDelegate] to play the relevant sounds;
/// - [DopamineDelegate] to signal to the UI that a Dopamine effect should be displayed.
class Game implements SocketDelegate, AudioPlayerDelegate, DopamineDelegate
{
    static const String _waitingMessage = "Waiting for 2-4 players!";

    /// Server inputs are relayed to the various UI components to reflect a change in the state of the app;
    /// this relaying operation is handled through the [Stream]s and [Sink]s used inside the following four 
    /// Business LOgic Componentss.
    final InGameBloc inGameBloc;
    final GameStatsBloc gameStatsBloc;
    final GameConnectionBloc gameConnectionBloc;
    final SceneBloc sceneBloc;

    /// SocketClient handle & its relevant callbacks.
    SocketClient _client;
    SocketMessageCallback onMessage;
    SocketReadyCallback onReady;
    SocketConnectionCallback onConnectionChanged;

    /// Callbacks for [DopamineDelegate].
    DopamineScoreCallback onScored;
    DopamineLifeLostCallback onLifeLost;

    List<AudioPlayer> _audioPlayers = new List<AudioPlayer>();
    
    /// In the constructor all the BLOCs are initialized properly, together with the apppriate handles.
    Game({InGameBloc igb, GameStatsBloc gsb, GameConnectionBloc gcb, SceneBloc sb}) :
        inGameBloc = igb ?? new InGameBloc(),
        gameStatsBloc = gsb ?? new GameStatsBloc(),
        gameConnectionBloc = gcb ?? new GameConnectionBloc(),
        sceneBloc = sb ?? new SceneBloc()
    {
        /// [SocketClient] is initialized with a unique ID so that the server has a way to identify
        /// which tablet is connected to which socket.
        _client = new SocketClient(this, new Uuid().v4());
        /// [SocketDelegate] callbacks are also registered on this object, acting as a delegate.
        onReady = handleReady;
        onMessage = onSocketMessage;
		onConnectionChanged = handleConnectionChange;
        /// Initalize the message in the bubble shown in the lobby. 
        resetSceneMessage();
    }

    bool handleReady()
	{
		bool readyState = !gameConnectionBloc.last.isReady;
        gameConnectionBloc.setLast(isReady: readyState);
		return readyState;
	}

    void handleConnectionChange()
    {
        gameConnectionBloc.setLast(isConnected: _client.isConnected);
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

    /// This function converts all the payloads in JSON format that arrive from the server. 
    /// Depending on the type of message that is delivered, a different callback is used.
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
                debugPrint("UNKNOWN MESSAGE: $jsonMsg");
                break;
        }
    }
    
    /// This callback is actioned every time a message arrives, so that every client has a consistent view of
    /// the status of the game.
    void setGameStatus(bool isServerInGame, bool isClientInGame, bool doesServerThinkImReady, bool doesServerThinkStart)
	{
        gameConnectionBloc.setLast(
            isReady: doesServerThinkImReady, 
            markedStart: doesServerThinkStart, 
            canBeReady: !isServerInGame /// we can only mark ready if the server isn't already in a game.
        );
        if(!inGameBloc.last.isOver && connection.isPlaying && !isClientInGame)
        {
            showGameOver(false, false);
        }
	}

    /// If a new message has arrived, play the new_command sound and show the message with the command in the bubble.
	void onTalk(String msg)
	{
		playAudio("assets/audio/new_command.wav");

        sceneBloc.setLast(sceneMessage: msg);
	}

    /// When a game starts, the server sends over the list of commands that the local player will have on the screen.
    /// Some fields are reset to make sure that the game status is consistent for the local player, and the character 
    /// scene is updated by choosing a random stakeholder to zoom in to.
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
        
        /// Manually reset these fields.
        sceneBloc.nullifyParams(true, true, true);
        sceneBloc.setLast(
			sceneState: TerminalSceneState.BossOnly,
            sceneCharacterIndex: new Random().nextInt(4)
        );
        gameStatsBloc.setLast(initials: "");
    }

    /// When a game ends, show the game over stats page, and update the [GameStatsBloc] with the server data.
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
	}

    /// This function updates the stream for the [InGame] widget, raising the appropriate flags.
    void showGameOver(bool isHighScore, bool didDie)
	{
        inGameBloc.setLast(hasWon: isHighScore, isOver: true);
        /// Manually update the fields, and call [SceneBloc.setLast()] so that they are updated properly.
        sceneBloc.nullifyParams(true, true, true);
        sceneBloc.setLast();
	}

    /// When a player receives a new task, the [TerminalScene] needs to have refreshed information about
    /// the message to show, the start&end time, and the AudioPlayer is triggered with the appropriate sound.
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


    /// Update the [GameConnectionBloc] list so that the [LobbyWidget] can show how many players are in the game, and which ones are ready to start.
	onPlayersList(List<bool> readyList)
	{
        gameConnectionBloc.setLast(arePlayersReady: readyList);
        resetSceneMessage();
	}

    /// Whenever a Game Control is actioned(e.g. a button press, a slider is set, etc.) the server validate that command with the 
    /// current set of actions that need to be performed. Depending on the correctness of the action, a 'success' or a 'fail' sound
    /// is played, and a corresponding [DopamineDelegate] effect is shown on screen.
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
	
    /// Update the [TerminalScene] message.
    void onTaskFail(String msg)
	{
	    sceneBloc.setLast(sceneMessage: msg);
	}

    /// Update the [TerminalScene] message and reset the start and end time for the current command.
	void onTaskComplete(String msg)
	{
        sceneBloc.nullifyParams(false, true, true);
        sceneBloc.setLast(sceneMessage: msg);
	}

    /// The server sends over how many lives are available for the team playing. If any lives have been lost
    /// play a sound and show a [DopamineDelegate] effect in the center of the screen.
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
    
    /// Updated score for the team.
    void onScoreChanged(int value)
	{
        if(gameStatsBloc.score != value)
        {
            gameStatsBloc.setLast(score: value);
        }
	}

    /// In the [GameStats] screen, if a player has successfully entered the initials, these are passed back to the rest
    /// of the team, and the that allowed to input initials is greyed out.
	void onServerInitials(String initials)
	{
        if(gameStatsBloc.initials != initials)
        {
            gameStatsBloc.setLast(initials: initials);
        }
	}

    /// Set lobby message depending on how many players are ready in the list.
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

    /// When the game goes back to the lobby, the [_TerminalState] calls this function in order to reset all the appropriate fields 
    /// and parameters and start from a clean slate.
    backToLobby()
    {
        inGameBloc.setLast(gridDescription: [], isOver: false);
        String message = connection.arePlayersReady.fold<int>(0, (int count, bool value) { if(value) { count++; } return count;} ) >= 2 ? "Come on, we've got a deadline to meet!" : _waitingMessage;
        sceneBloc.setLast(sceneMessage: message, sceneState: TerminalSceneState.All);
        gameConnectionBloc.setLast(isReady: false, markedStart: false, isPlaying: false);
    }

    /// Helper private function that'll load a file from the assets and write it to disk.
    /// Upon loading the file for the first time, and thus writing it to disk, the game could slow down.
    /// For any subsequent [_loadFile()] call everything should go smoothly. 
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
    
    /// Implementation for the [AudioPlayerDelegate] interface.
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

    /// This getter exposes the [SocketClient] so that certain UI elements can directly
    /// plug into some if its functions to use as callbacks.
    SocketClient get client => _client;
    ConnectionInfo get connection => gameConnectionBloc.last;
}