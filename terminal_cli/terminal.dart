import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';

ArgResults argResults;

const String ipArg = "address";

void main(List<String> arguments) 
{
	exitCode = 0;
	final parser = new ArgParser()
		..addOption(ipArg, abbr: 'a');

	argResults = parser.parse(arguments);

	if(argResults[ipArg] == null)
	{
		print("IP Address is required, specify with -a");
		exitCode = 1;
		return;
	}

	final SocketClient client = new SocketClient(argResults[ipArg]);
	client.connect();
}

class SocketClient
{
	static const int ReconnectMinSeconds = 2;
	static const int ReconnectMaxSeconds = 10;
	int _reconnectSeconds = ReconnectMinSeconds;

	final String _address;
	final String _uniqueId;
	bool _isConnected = false;
	Socket _socket;
	Timer _reconnectTimer;
	Timer _pingTimer;

	SocketClient(this._address) : _uniqueId = new Uuid().v4();

	void connect()
	{
		if(_socket != null)
		{
			_socket.close().then((dynamic)
			{
				connect();
			});
			_socket = null;
			return;
		}

		if(_reconnectTimer != null)
		{
			_reconnectTimer.cancel();
		}

		Socket.connect(_address, 8080, timeout:new Duration(seconds: 5))
			.catchError
			(
				(e)
				{
					print("Socket caught error: $e");
					reconnect();
				}
			)
			.then
			(
				(socket) 
				{
					if(socket == null)
					{
						print("Connected with null socket?");
						if(!_isConnected)
						{
							reconnect();
						}
						return;
					}
					print("Connected: $socket");
					_socket = socket;
					sendPing();

					String data = "";
					_socket.transform(utf8.decoder).listen((message)
					{
						data += message;
						while(true)
						{
							int idx = data.indexOf("\n");
							if(idx == -1)
							{
								return;
							}
	
							String encodedJson = data.substring(0, idx);
							//print("Received: $encodedJson");
							try
							{
								var jsonMsg = json.decode(encodedJson);
								String msg = jsonMsg['message'];
								var payload = jsonMsg['payload'];

								var gameActive = jsonMsg['gameActive'];
								var inGame = jsonMsg['inGame'];
								var isClientReady = jsonMsg['isReady'];
								var didClientMarkStart = jsonMsg['markedStart'];
								
								if(gameActive is bool && isClientReady is bool && inGame is bool)
								{
									if(!gameActive && !isClientReady)
									{
										_socket?.writeln(formatJSONMessage("ready", true));
										_socket?.writeln(formatJSONMessage("startGame", true));
										print("I am ready!");
									}
								}
								switch(msg)
								{
									case "commandsList":
										String commands = (payload as List<dynamic>).map((dynamic d)
										{
											return "${d["title"]} ${d["taskType"]}";
										}).toList().toString();
										print("Commands: $commands");
										break;
									case "newTask":
										print("Task: ${payload['message']}");
										break;
								}
							}
							on FormatException catch(e)
							{
								print("Wrong Message Formatting, not JSON: $encodedJson");
								print(e);
							}
							data = data.substring(idx+1);
						}
					},

					onDone: ()
					{
						print("Socket done.");
						reconnect();
					},
					
					onError: ()
					{
						print("Socket error.");
						reconnect();
					});
				}
			);
	}

	void reconnect()
	{
		if(_reconnectTimer != null)
		{
			_reconnectTimer.cancel();
			_reconnectTimer = null;
		}
		if(_socket != null)
		{
			_socket.close();
			_socket = null;
		}
		_isConnected = false;


		int delay = _reconnectSeconds;
		_reconnectSeconds = (_reconnectSeconds * 1.5).round().clamp(ReconnectMinSeconds, ReconnectMaxSeconds);

		print("Attempting socket reconnect in $delay seconds.");
		_reconnectTimer = new Timer(new Duration(seconds: delay), connect);
	}

	void sendPing()
	{
		if(_socket == null)
		{
			return;
		}
		if(_pingTimer != null)
		{
			_pingTimer.cancel();
			_pingTimer = null;
		}
		
		_socket.writeln(formatJSONMessage("hi", _uniqueId));

		_pingTimer = new Timer(new Duration(seconds: 5), sendPing);
	}

	static String formatJSONMessage<T>(String msg, T payload)
    {
        return json.encode({
            "message": msg,
            "payload": payload
        });
    }
}