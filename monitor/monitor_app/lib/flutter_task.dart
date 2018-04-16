import "dart:async";
import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "dart:convert";
import "dart:collection";

class FlutterTask
{
	static int _next_id = 0;
	int _id = 0;
	String _message = "";
	String _path;
	VoidCallback _readyHandler;
	VoidCallback _reloadedHandler;
	bool _ready = false;

	static final platform = const BasicMessageChannel("flutter/flutterTask", const JSONMessageCodec())..setMessageHandler(onPlatformMessage);
	static HashMap<int, FlutterTask> _lookup = new HashMap<int, FlutterTask>();

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
		//print("MESSAGE IS ${message}");
	}

	addMessage(String message)
	{
		// Seems like there's no need to buffer lines, keep an eye on this.
		this.onReceivedLine(message);
		// _message += message;
		// int idx = _message.indexOf("\n");    
		// if(idx != -1)
		// {
		// 	String line = _message.substring(0, idx);
		// 	_message = _message.substring(idx+1);
		// 	this.onReceivedLine(line);
		// }
	}

	onReceivedLine(String line)
	{
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
			//print("RESULT ${result["soundID"]}");
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
			//print("RESULT ${result["soundID"]}");
		} 
		on PlatformException catch (e) 
		{
			return false;
    	}
		return true;
	}
}