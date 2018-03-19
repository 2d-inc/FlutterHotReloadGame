import "dart:async";
import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "dart:convert";
import "dart:collection";

class Sound
{
	static int _next_id = 0;
	int _id = 0;
	double _volume = 1.0;
	bool _loop = false;
	static final platform = const BasicMessageChannel("flutter/sound", const JSONMessageCodec())..setMessageHandler(onPlatformMessage);
	static HashMap<int, Sound> _lookup = new HashMap<int, Sound>();
	bool _isPlaying = false;

	Sound()
	{
		_id = _next_id++;
	}

	static Future<dynamic> onPlatformMessage(dynamic data) async
	{
		int id = data["soundID"];
		bool isPlaying = data["isPlaying"] == 1;
		print("Received platform message ${id} ${isPlaying}");
		Sound sound = _lookup[id];
		if(sound != null)
		{
			sound._isPlaying = isPlaying;
		}

		if(!isPlaying)
		{
			_lookup.remove(id);
		}
	}

	Future<bool> load(filename) async
	{
		try 
    	{
			final dynamic result = await platform.send({"method":"make", "args":{"filename":filename}, "soundID":_id});
			//print("RESULT ${result["soundID"]}");
		} 
		on PlatformException catch (e) 
		{
			return false;
    	}
    	return true;
	}

	Future<bool> play([bool loop = false, double volume = 1.0]) async
	{
		_volume = volume;
		_loop = loop;
		try 
    	{
			final dynamic result = await platform.send({"method":"play", "args":{"loop":loop, "volume":volume}, "soundID":_id});
		} 
		on PlatformException catch (e) 
		{
			return false;
    	}

    	_lookup[_id] = this;
    	return true;
	}

	Future<bool> stop() async
	{
		try 
    	{
			final dynamic result = await platform.send({"method":"stop", "args":{}, "soundID":_id});
		} 
		on PlatformException catch (e) 
		{
			return false;
    	}
    	return true;
	}

	Future<bool> pause() async
	{
		try 
    	{
			final dynamic result = await platform.send({"method":"pause", "args":{}, "soundID":_id});
		} 
		on PlatformException catch (e) 
		{
			return false;
    	}
    	return true;
	}

	Future<bool> setVolume(double value) async
	{
		_volume = value;

		try 
    	{
			final dynamic result = await platform.send({"method":"setVolume", "args":{"value":value}, "soundID":_id});
		} 
		on PlatformException catch (e) 
		{
			return false;
    	}
    	return true;
	}
}