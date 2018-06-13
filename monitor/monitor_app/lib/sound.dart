import "dart:async";
import "dart:collection";

import "package:flutter/services.dart";

/// This object interacts with Objective-C through a message channel. This object and FLEAudioPlayer in [FLEAudioPlayerPlugin.m] 
/// subscribe to the same channel, so that they can communicate.
/// When a new message is sent over the 'platform' [BasicMessageChannel] the corresponding method is actioned.
/// A static field is used to identify a Sound after initialization, and is registered the static HashMap when
/// the [play()] function is called.
/// This is needed in order to communicate with the underlying macOS platform.
class Sound
{
	static final platform = const BasicMessageChannel("flutter/sound", const JSONMessageCodec())..setMessageHandler(onPlatformMessage);
	static int _next_id = 0;
	static HashMap<int, Sound> _lookup = new HashMap<int, Sound>();

	int _id = 0;
	double _volume = 1.0;
	bool _loop = false;
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

	Future<bool> load(String filename) async
	{
		try 
    	{
			final dynamic result = await platform.send({"method":"make", "args":{"filename":filename}, "soundID":_id});
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