import "dart:io";
import "dart:ui";
import "dart:async";
import "dart:convert";
import "package:flutter/foundation.dart";
import "package:path_provider/path_provider.dart";
import "delegates/socket_delegate.dart";

class SocketClient
{
	static const int ReconnectMinSeconds = 2;
	static const int ReconnectMaxSeconds = 10;
	
    Socket _socket;
	SocketDelegate _terminal;
	Timer _reconnectTimer;
	Timer _pingTimer;
	int _reconnectSeconds = ReconnectMinSeconds;
	bool _isConnected = false;
	VoidCallback onConnectionChanged;
	String _address;
	String _uniqueId;

    SocketClient(this._terminal, this._uniqueId)
	{
		if(Platform.isAndroid)
		{
			_address = "10.0.2.2";
		}
		else
		{
			_address = InternetAddress.LOOPBACK_IP_V4.address;
		}

		getApplicationDocumentsDirectory().then((Directory dir)
		{
			File file = new File("${dir.path}/ip.txt");
			try
			{
				String ip = file.readAsStringSync();
				if(validateIpAddress(ip))
				{
					_address = ip;
				}
				connect();
			}
			catch(FileSystemException)
			{
				connect();
			}
		});
	}

	bool get isConnected
	{
		return _isConnected;
	}

	String get address => _address;
	set address(String value)
	{
		if(value == _address)
		{
			return;
		}
		_address = value;
		connect();
		
		getApplicationDocumentsDirectory().then((Directory dir)
		{
			File file = new File("${dir.path}/ip.txt");
			file.writeAsStringSync(_address);
		});
	}

    static String formatJSONMessage<T>(String msg, T payload)
    {
        return json.encode({
            "message": msg,
            "payload": payload
        });
    }

	void dispose()
	{
		_socket?.close();
	}

	void onReady()
	{
		// bool state = _terminal.handleReady();
		bool state = _terminal.onReady();
		_socket?.writeln(formatJSONMessage("ready", state));
	}

	void onStart()
	{
		_socket?.writeln(formatJSONMessage("startGame", true));
	}

	void sendCommand(String taskType, int value)
	{
		_socket?.writeln(formatJSONMessage("clientInput", {"type":taskType, "value":value}));
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

		if(onConnectionChanged != null)
		{
			onConnectionChanged();
		}

		int delay = _reconnectSeconds;
		_reconnectSeconds = (_reconnectSeconds * 1.5).round().clamp(ReconnectMinSeconds, ReconnectMaxSeconds);

		debugPrint("Attempting socket reconnect in $delay seconds.");
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

	set initials(String initials)
	{
		_socket?.writeln(formatJSONMessage("initials", initials));
	}
	
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

		print("Attempting connection to " + address + " on port 8080");
		Socket.connect(address, 8080, timeout:new Duration(seconds: 5))
			.catchError
			(
				(e)
				{
					debugPrint("Socket caught error: $e");
					reconnect();
				}
			)
			.then(
				(socket) 
				{
					if(socket == null)
					{
						debugPrint("Connected with null socket?");
						if(!_isConnected)
						{
							reconnect();
						}
						return;
					}
					print("CONNECTION CALLBACK");
					if(_isConnected)
					{
						// This seems to occur when a connection times out, but then mysteriously
						// comes back from the dead and calls its connection handler. This shouldn't
						// happen with our new handler ordering, but this is a nice sanity check.
						print("Good socket was already connected, kill this zombie socket.");
						socket.close();
						return;
					}
					_isConnected = true;

					if(onConnectionChanged != null)
					{
						onConnectionChanged();
					}
					debugPrint("Socket connected");
					// Reset to min connect time for future reconnects.
					_reconnectSeconds = ReconnectMinSeconds;

					// Store socket.
					_socket = socket;

					// Let the server know who we are so they can kill older connections if they exist.
					sendPing();

					// Listen for messages.
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
							try
							{
								var jsonMsg = json.decode(encodedJson);
								print("GOT MESSAGE $jsonMsg");
                                _terminal.onMessage(jsonMsg);
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
						debugPrint("Socket done.");
						reconnect();
					},
					
					onError: (Object error)
					{
						debugPrint("Socket error. $error");
						reconnect();
					});
				});
	}
}


bool validateIpAddress(String ip)
{
	List<String> values = ip.split('.');
	if(values.length != 4)
	{
		return false;
	}
	else
	{
		for(String s in values)
		{
			int ipValue = int.tryParse(s) ?? -1;
			if(ipValue < 0 || ipValue > 255)
			{
				return false;
			}
		}
	}
	return true;
}