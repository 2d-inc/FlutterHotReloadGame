import 'package:flutter/widgets.dart';

import "game.dart";

/// By extending an [InheritedWidget] this class serves the purpose of being accessible anywhere in the widget tree.
/// In fact, it's used as a Wrapper for the whole app.
/// Moreover it creates an instance of the [Game], that is responsible for running 
/// all the logic for the application, the socket delegation and the business logic.
class GameProvider extends InheritedWidget
{
    final Game game;

    GameProvider({Key key, Game game, Widget child}) : 
        game = game ?? new Game(),
        super(key: key, child: child);

    @override
    updateShouldNotify(InheritedWidget oldWidget) => true;

    /// This static [of()] function allows to access the instance of the game anywhere in the widget tree.
    static Game of(BuildContext context) => (context.inheritFromWidgetOfExactType(GameProvider) as GameProvider).game;
}