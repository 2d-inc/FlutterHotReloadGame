import "dart:async";
import "dart:collection";

import "package:flutter/foundation.dart";
import "package:flutter/services.dart";

typedef void StringCallback(String element); 

/// This object interacts with Objective-C through a message channel. This object and FlutterTask in [FLEFlutterTaskPlugin.m] 
/// subscribe to the same channel, so that they can communicate.
/// When a new message is sent over the 'platform' [BasicMessageChannel] the corresponding method is actioned.
/// A static field is used to identify a FlutterTask after initialization, and is registered the static HashMap when
/// the [load()] function is called.
class FlutterTask
{
	static final platform = const BasicMessageChannel("flutter/flutterTask", const JSONMessageCodec())..setMessageHandler(onPlatformMessage);
	static HashMap<int, FlutterTask> _lookup = new HashMap<int, FlutterTask>();
	static int _next_id = 0;

	int _id = 0;
	String _message = "";
	String _path;
	VoidCallback _readyHandler;
	VoidCallback _reloadedHandler;
	StringCallback _outputHandler;
	bool _ready = false;


	FlutterTask(String path)
	{
		_id = _next_id++;
		_path = path;
	}

	void onReady(VoidCallback callback) 
	{
		_readyHandler = callback;
	}

	void onReload(VoidCallback callback) 
	{
		_reloadedHandler = callback;
	}

	void onStdout(StringCallback callback)
	{
		_outputHandler = callback;
	}

    /// Handle incoming messages with the appropriate registered FlutterTask.
    /// A Task that should react to this message should've been registere in [load()].
	static Future<dynamic> onPlatformMessage(dynamic data) async
	{
		int id = data["taskID"];
		String message = data["message"];
		FlutterTask task = _lookup[id];
		if(task == null)
		{
			return;
		}
		task.addMessage(message);
	}

	addMessage(String message)
	{
		// Seems like there's no need to buffer lines, keep an eye on this.
		this.onReceivedLine(message);
	}

    /// Any incoming message from the is processed here. 
    /// If this FlutterTask can handle the current message, it'll have a registered callback.
	onReceivedLine(String line)
	{
		line = line.trim();
		
		if(_outputHandler != null && line.isNotEmpty)
		{
			List<String> lines = line.split("\n");
			for(String line in lines)
			{
				_outputHandler(line);
			}
		}

		if(!_ready && line.indexOf("To hot reload your app on the fly, press \"r\".") != -1)
		{
			_ready = true;
			if(_readyHandler != null)
			{
				_readyHandler();
			}
		}
		else if(line.indexOf(new RegExp(r"Reloaded [0-9]+ of [0-9]+ libraries in [0-9,]+ms.")) != -1)
		{
			if(_reloadedHandler != null)
			{
				_reloadedHandler();
			}
		}
	}

	Future<bool> load(String device) async
	{
		try 
		{
			final dynamic result = await platform.send({"method":"make", "args":{"root":_path, "device":device}, "taskID":_id});
		} 
		on PlatformException catch (e) 
		{
			return false;
		}

		_lookup[_id] = this;
		return true;
	}

	Future<bool> hotReload() async
	{
		try 
		{
			final dynamic result = await platform.send({"method":"reload", "args":{}, "taskID":_id});
		} 
		on PlatformException catch (e) 
		{
			return false;
		}
		return true;
	}

	Future<bool> terminate() async
	{
		try 
		{
			final dynamic result = await platform.send({"method":"terminate", "args":{}, "taskID":_id});
		} 
		on PlatformException catch (e) 
		{
			return false;
		}
		_lookup.remove(_id);
		return true;
	}

	Future<String> read(String filename) async
	{
		try 
    	{
			final dynamic result = await platform.send({"method":"read", "args":{"filename":_path+filename}, "taskID":_id});
			if(result == null)
			{
				return null;
			}
			return result["contents"];
		} 
		on PlatformException catch (e) 
		{
			return null;
    	}
	}

	Future<bool> write(String filename, String contents) async
	{
		try 
    	{
			final dynamic result = await platform.send({"method":"write", "args":{"filename":_path+filename, "contents":contents}, "taskID":_id});
		} 
		on PlatformException catch (e) 
		{
			return false;
    	}
		return true;
	}
}