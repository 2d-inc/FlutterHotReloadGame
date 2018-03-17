#import "FLEAudioPlayerPlugin.h"
#import "FLEViewController.h"
#import <AVFoundation/AVFoundation.h>

static NSString *const kPlatformMethodNameKey = @"method";
static NSString *const kPlatformMethodArgsKey = @"args";
static NSString *const kPlatformSoundIDKey = @"soundID";

static NSString *const kAudioPlayerChannelName = @"flutter/sound";

@interface FLEAudioPlayerPlugin ()
@property(nonatomic, strong, nonnull) NSMutableDictionary<NSNumber *, AVAudioPlayer *> *sounds;
@property NSDictionary* soundApiMethods;
@end

@implementation FLEAudioPlayerPlugin

@synthesize controller = _controller;

typedef NSMutableDictionary*(^ ApiMethod)(NSNumber*, NSDictionary*);

- (void)advanceTimer:(NSTimer* )timer
{
    NSNumber* soundId = timer.userInfo;
    AVAudioPlayer* player = _sounds[soundId];
    if(player == nil)
    {
        [timer invalidate];
        return;
    }
    NSError *error = nil;
    NSMutableDictionary *json = [NSMutableDictionary dictionaryWithObject:soundId forKey:kPlatformSoundIDKey];
    json[@"isPlaying"] = [NSNumber numberWithInt:player.isPlaying ? 1 : 0];
    NSData *message = [NSJSONSerialization dataWithJSONObject:json options:0 error:&error];
    if (message == nil || error != nil)
    {
        NSLog(@"ERROR: could send platform response message: %@", error.debugDescription);
        return;
    }
    
    [_controller sendPlatformMessage:message onChannel:kAudioPlayerChannelName];
    if(!player.isPlaying)
    {
        [timer invalidate];
    }
}

- (instancetype)init 
{
	self = [super init];
	if(self != nil)
	{
		_sounds = [NSMutableDictionary dictionary];
       
		_soundApiMethods = 
		@{
            @"make":^NSMutableDictionary*(NSNumber* soundId, NSDictionary* args)
            {
                NSString* filename = args[@"filename"];
                NSString *path = [NSString stringWithFormat:@"%@/flutter_assets/%@", [[NSBundle mainBundle] resourcePath], filename];
                NSURL *soundUrl = [NSURL fileURLWithPath:path];
                
                AVAudioPlayer* player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundUrl error:nil];
                _sounds[soundId] = player;
                NSMutableDictionary *response = [NSMutableDictionary dictionaryWithObject:soundId forKey:kPlatformSoundIDKey];

                return response;
            },
            @"play":^NSMutableDictionary*(NSNumber* soundId, NSDictionary* args)
            {
                NSNumber* loop = args[@"loop"];
                NSNumber* volume = args[@"volume"];
                
                AVAudioPlayer* player = _sounds[soundId];
                if(player == nil)
                {
                    return nil;
                }
                [player setVolume:[volume floatValue]];
                player.numberOfLoops = [loop intValue] == 0 ? 0 : -1;
                
                if(player.isPlaying)
                {
                    return nil;
                }
                
                [player play];
                [NSTimer scheduledTimerWithTimeInterval:2.0
                                                 target:self
                                               selector:@selector(advanceTimer:)
                                               userInfo:soundId
                                                repeats:NO];
                return nil;
            },
            @"stop":^NSMutableDictionary*(NSNumber* soundId, NSDictionary* args)
            {
                AVAudioPlayer* player = _sounds[soundId];
                if(player == nil)
                {
                    return nil;
                }
                [player stop];
                return nil;
            },
            @"pause":^NSMutableDictionary*(NSNumber* soundId, NSDictionary* args)
            {
                AVAudioPlayer* player = _sounds[soundId];
                if(player == nil)
                {
                    return nil;
                }
                [player pause];
                return nil;
            },
            @"setVolume":^NSMutableDictionary*(NSNumber* soundId, NSDictionary* args)
            {
                NSNumber* volume = args[@"value"];
                
                AVAudioPlayer* player = _sounds[soundId];
                if(player == nil)
                {
                    return nil;
                }
                [player setVolume:[volume floatValue]];
                return nil;
            }
		};

	}
	return self;
}

#pragma FLEPlugin implementation

- (NSString *)channel 
{
	return kAudioPlayerChannelName;
}

// NSDictionary *SoundApiMethods = 
// @{
// 		@"make": [NSValue valueWithPointer:makeSound]
// };


- (nullable id)handlePlatformMessage:(NSDictionary *)message
{
	NSString *methodName = message[kPlatformMethodNameKey];
	NSDictionary *methodArgs = message[kPlatformMethodArgsKey];
	NSNumber *soundID = message[kPlatformSoundIDKey];
    NSLog(@"METHOD %@", methodName);
	ApiMethod method = _soundApiMethods[methodName];
    if(method == nil)
    {
        return nil;
    }
    return method(soundID, methodArgs);
	
	/*
	__weak FLEAudioPlayerPlugin *weakself = self;
	NSLog(@"METHOD NAME: %@", methodName);
	NSString *path = [NSString stringWithFormat:@"%@/flutter_assets/assets/step.mp3", [[NSBundle mainBundle] resourcePath]];
	NSLog(@"PATH: %@", path);
	NSURL *soundUrl = [NSURL fileURLWithPath:path];
	_audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundUrl error:nil];
	_audioPlayer.numberOfLoops = 20;
	[_audioPlayer play];
	[_controller sendPlatformMessage:message onChannel:kAudioPlayerChannelName];
	return nil;*/
}
@end
