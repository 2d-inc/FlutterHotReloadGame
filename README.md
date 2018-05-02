# BiggerLogo
<img width="350" alt="portfolio_view" src="https://github.com/2d-inc/BiggerLogo/raw/master/hot_reload_twitter_short.mov.gif">

## Building
The Monitor App builds on OSX via XCode. Please read the [instructions](https://github.com/2d-inc/BiggerLogo/wiki/Building).

## Server
The server code is located in [/monitor/monitor_app/lib/server.dart](https://github.com/2d-inc/BiggerLogo/blob/master/monitor/monitor_app/lib/server.dart).

## Client
The client code is located in [/terminal_app/lib/main.dart](https://github.com/2d-inc/BiggerLogo/blob/master/terminal_app/lib/main.dart).

### IP
The Monitor App binds to ANY_IP_V4 which allows it to respond to incoming requests on any available IP. This removes the requirement from binding to a specific IP address in the Monitor app.

The Terminal App will store an IP address to connect to in a file and reload it when the app boots. This value can be changed by tapping three times on the top left corner of the Terminal App. Changing the IP address will force a reconnect and it will update the locally stored IP address so that it'll be available for next boot.
