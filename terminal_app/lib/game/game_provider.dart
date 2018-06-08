import 'package:flutter/widgets.dart';

import "game.dart";

class GameProvider extends InheritedWidget
{
    final Game game;

    GameProvider({Key key, Game game, Widget child}) : 
        game = game ?? new Game(),
        super(key: key, child: child);

    @override
    updateShouldNotify(InheritedWidget oldWidget) => true;

    static Game of(BuildContext context) => (context.inheritFromWidgetOfExactType(GameProvider) as GameProvider).game;
}