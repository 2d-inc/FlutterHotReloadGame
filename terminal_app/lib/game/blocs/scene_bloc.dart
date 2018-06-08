import "dart:async";

import "package:rxdart/rxdart.dart";

import "../../character_scene.dart";

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
    SceneInfo _last = SceneInfo.seed();
    BehaviorSubject<SceneInfo> _sceneController = new BehaviorSubject();
    Stream<SceneInfo> get stream => _sceneController.stream;
    Sink<SceneInfo> get sink => _sceneController.sink;
    
    dispose()
    {
        _sceneController.close();
    }

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