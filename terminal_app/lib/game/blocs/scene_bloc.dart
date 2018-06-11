import "dart:async";

import "package:rxdart/rxdart.dart";

import "../widgets/character_scene/terminal_scene.dart";

class SceneInfo
{
    final String sceneMessage;
    final DateTime commandStartTime;
    final DateTime commandEndTime;
    final TerminalSceneState sceneState;
    final int sceneCharacterIndex;

    SceneInfo(this.sceneMessage, this.commandStartTime, this.commandEndTime, this.sceneState, this.sceneCharacterIndex);

    SceneInfo.seed({ this.sceneMessage: "", DateTime commandStartTime, DateTime commandEndTime, this.sceneState: TerminalSceneState.All, this.sceneCharacterIndex: 0 }) :
        commandStartTime = commandStartTime ?? new DateTime.now(),
        commandEndTime = commandEndTime ?? new DateTime.now();
}

/// This BLOC is used to communicate with the [TerminalScene] and [CommandTimer] widgets.
class SceneBloc
{
    /// Keep a reference to the last element added to the [Stream]
    /// and initialize to a default 'empty' value.
    SceneInfo _last = SceneInfo.seed();
    
    BehaviorSubject<SceneInfo> _sceneController = new BehaviorSubject();
    Stream<SceneInfo> get stream => _sceneController.stream;
    Sink<SceneInfo> get sink => _sceneController.sink;
    
    dispose()
    {
        _sceneController.close();
    }

    /// This function takes care of 'diffing' the last element of the Stream
    /// with a new one so that any incoming new data is passed correctly to the
    /// [StreamBuilder] widgets that are listening.
    setLast({ String sceneMessage, TerminalSceneState sceneState, DateTime commandStartTime, DateTime commandEndTime, int sceneCharacterIndex })
    {
       var info = new SceneInfo(
            sceneMessage ?? last.sceneMessage, 
            commandStartTime ?? last.commandStartTime,
            commandEndTime ?? last.commandEndTime,
            sceneState ?? last.sceneState,
            sceneCharacterIndex ?? last.sceneCharacterIndex
        );
        _last = info;
        _sceneController.add(info);
    }

    SceneInfo get last => _last;
    
    /// The [TerminalScene] relies on some parameters to be null when reset or not available.
    nullifyParams(bool message, bool start, bool end)
    {
        if(message || start || end)
        {
            _last = new SceneInfo(
                message ? null : last.sceneMessage, 
                start ? null : last.commandStartTime, 
                end ? null : last.commandEndTime, 
                last.sceneState, 
                last.sceneCharacterIndex
            );
        }
    }
}