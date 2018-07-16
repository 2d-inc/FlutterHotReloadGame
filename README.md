# Flutter Hot Reload Game

The Flutter Hot Reload Game was first shown at Google I/O 2018, and it's entirely built with Flutter!

<img width="350" alt="portfolio_view" src="https://github.com/2d-inc/BiggerLogo/raw/master/hot_reload_twitter_short.mov.gif">

## Overview

The game works by connecting together three Flutter applications:
1. **Tablet App:**<br />
Runs on Tablets (tested on Pixel C, Nexus 9, Pixelbooks with the Android Runtime), and it is the core experience of the game. The game has been built to be played by 2-4 players. 

2. **TV App**<br />
A Flutter macOS application that can be launched from XCode.<br />
It runs the server logic for the tablets and for the Simulator App that's supposed be running next to it. This app will show the game lobby when no game is being played; once two or more players initiate a game, it'll show a virtual monitor with the code of the Simulator App as it updates in real time: whenever one of the players presses a button or moves a slider, the line of code related to that update is highlighted, and the Simulator App is also updated with the new state. <br />
There will be two buttons on virtual monitor: a _"Run"_ button and a _"Restart"_ button. The **Run** button will (re)start the Simulator application if a Simulator or Emulator device is running in the system and it can be detected in the local network. The **Restart** button will stop the current game, and send the players to the game lobby (useful if a player walks away, or for debugging purposes).

3. **Simulator App**<br />
It should run in a virtual phone device (ideally an iPhone 8 Plus Simulator or Android Emulator with a Pixel 2 Device). This virtual device should be appropriately sized so that it can be placed on top of the TV App: the TV App shows a background image with a monitor and a phone dock below it. The Simulator is meant to be placed as if the phone was docked in front of the screen. <br />
The App connects to the server (TV) and it'll be _Hot Reloaded_ every time a player presses a button or moves a slider on a playing tablet - so be careful about randomly pressing buttons, your team will lose points!

## Building

More detailed instructions can be found [here](https://github.com/2d-inc/BiggerLogo/wiki/Building).

The Tablet App can be built and installed on any supported device with the apppriate SDK commands: [Android](https://flutter.io/android-release/) and [iOS](https://flutter.io/ios-release/) may require different steps.

The TV App builds on macOS via XCode.

## Custom Widgets

One of Flutter's biggest strengths is its flexibility, because it exposes the architecture of its components, which can be built entirely from scratch. Since the UI is entirely _Widget-based_, it is possible to create custom Widgets out of the SDK's most basic elements. The Tablet App and the TV App rely heavily on these types of components (e.g. `flare_heart_widget.dart`): by combinining a `LeafRenderObject` with a `RenderObject`, any custom component can be created and placed in the Widget tree. 

For a more in-depth explanation, take a look at the [wiki page](https://github.com/2d-inc/BiggerLogo/wiki/Custom-Widgets).

## Custom Animations

The animated components in the Tablet and TV App use the [2Dimensions](www.2dimensions.com) custom libraries, Nima and Flare. A more detailed tutorial on how to use them in Flutter is available [here](https://www.2dimensions.com/learn/manual/export/flutter).

## Network

The server code is located in [/monitor/monitor_app/lib/server.dart](https://github.com/2d-inc/BiggerLogo/blob/master/monitor/monitor_app/lib/server.dart), while the client code is located in `/terminal_app/lib/game/socket_client.dart`.

### IP

The TV App binds to `ANY_IP_V4` which allows it to respond to incoming requests on any available IP. This removes the requirement from binding to a specific IP address in the TV App.

The Tablet App will store an IP address to connect to in a file and reload it when the app boots. This value can be changed by tapping three times on the top left corner of the Tablet App. Changing the IP address will force a reconnect and it will update the locally stored IP address so that it'll be available for next boot.

### Asynchronous Communication

The Tablet app uses Sinks & Streams to handle communication with the server, as well as Bussiness LOgic Components (BLOCs), which can be found in the `terminal_app/lib/blocs` folder. This scheme of communication has been detailed by Google at I/O in [this talk](https://www.youtube.com/watch?v=RS36gBEp8OI) and in [this blog post](https://medium.com/flutter-io/build-reactive-mobile-apps-in-flutter-companion-article-13950959e381).

An overview of this repo's implementation is also in the [wiki page](https://github.com/2d-inc/BiggerLogo/wiki/Asynchronous-Communication).