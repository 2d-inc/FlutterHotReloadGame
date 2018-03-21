#import "FLEFlutterTaskPlugin.h"
#import "FLEViewController.h"
#import <AVFoundation/AVFoundation.h>

static NSString *const kPlatformMethodNameKey = @"method";
static NSString *const kPlatformMethodArgsKey = @"args";
static NSString *const kPlatformFlutterTaskIDKey = @"taskID";

static NSString *const kFlutterTaskChannelName = @"flutter/flutterTask";

@interface FlutterTask : NSObject
{
	FLEViewController* viewController;
	NSNumber* taskId;
	NSString* path;
	NSString* device;
}
@property(nonatomic, strong, nonnull) NSPipe *inPipe;
@property(nonatomic, strong, nonnull) NSPipe *outPipe;
@property(nonatomic, strong, nonnull) NSTask *task;
@property(nonatomic, strong, nonnull) NSThread *thread;

@end
@implementation FlutterTask
- (void)thereIsData:(NSNotification *)notification
{
	NSString* stringData = [[NSString alloc] initWithData:[notification.object availableData] encoding:NSUTF8StringEncoding];
	[notification.object waitForDataInBackgroundAndNotify];
	NSError *error = nil;
	NSLog(@"Data %@", stringData);
	NSMutableDictionary *json = [NSMutableDictionary dictionaryWithObject:taskId forKey:kPlatformFlutterTaskIDKey];
	json[@"message"] = stringData;

	NSData *message = [NSJSONSerialization dataWithJSONObject:json options:0 error:&error];
	if (message == nil || error != nil)
	{
		NSLog(@"ERROR: could send platform response message: %@", error.debugDescription);
		return;
	}
	
	[viewController sendPlatformMessage:message onChannel:kFlutterTaskChannelName];
}
- (void) launch
{
	@autoreleasepool
	{
		_inPipe = [NSPipe new];
		_outPipe = [NSPipe new];
	
		_task = [NSTask new];
		[_task setLaunchPath:@"/bin/bash"];
		[_task setCurrentDirectoryPath:path];
		NSString* flutter = @"flutter run -d";
		flutter = [flutter stringByAppendingString:device];
		[_task setArguments:[NSArray arrayWithObjects:@"-l", @"-c", flutter, nil]];
		[_task setStandardInput:_inPipe];
		[_task setStandardOutput:_outPipe];
		
		NSFileHandle *fh = [_outPipe fileHandleForReading];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thereIsData:) name:NSFileHandleDataAvailableNotification object:fh];

		[fh waitForDataInBackgroundAndNotify];
		[_task launch];
		[_task waitUntilExit];
		
	}
}
- (instancetype)init:(FLEViewController*)theViewController taskId:(NSNumber*)theId path:(NSString*)thePath device:(NSString*)deviceName
{
	viewController = theViewController;
	taskId = theId;
	device = deviceName;
	path = thePath;
	_thread = [[NSThread alloc] initWithTarget:self selector:@selector(launch) object:nil];
	[_thread start];
	return self;
}

-(void)terminate
{
	[_task terminate];
	[_thread cancel];
	_inPipe = NULL;
	_outPipe = NULL;
	_task = NULL;
	_thread = NULL;

}
@end

@interface FLEFlutterTaskPlugin ()
@property(nonatomic, strong, nonnull) NSMutableDictionary<NSNumber *, FlutterTask *> *tasks;
@property NSDictionary* taskApiMethods;
@end

@implementation FLEFlutterTaskPlugin

@synthesize controller = _controller;

typedef NSMutableDictionary*(^ ApiMethod)(NSNumber*, NSDictionary*);

- (instancetype)init 
{
	self = [super init];
	if(self != nil)
	{
		_tasks = [NSMutableDictionary dictionary];
	   
		_taskApiMethods = 
		@{
			@"make":^NSMutableDictionary*(NSNumber* taskId, NSDictionary* args)
			{
				NSString* root = args[@"root"];
				NSString* device = args[@"device"];
				
				FlutterTask* task = [[FlutterTask alloc] init:_controller taskId:taskId path:root device:device];
				_tasks[taskId] = task;
				NSMutableDictionary *response = [NSMutableDictionary dictionaryWithObject:taskId forKey:kPlatformFlutterTaskIDKey];

				return response;
			},
			@"reload":^NSMutableDictionary*(NSNumber* taskId, NSDictionary* args)
			{
				FlutterTask* task = _tasks[taskId];
				if(task == nil)
				{
					return nil;
				}
				NSData *data = [@"r\n" dataUsingEncoding:NSUTF8StringEncoding];
				[[task.inPipe fileHandleForWriting] writeData:data];
				return nil;
			},
			@"terminate":^NSMutableDictionary*(NSNumber* taskId, NSDictionary* args)
			{
				FlutterTask* task = _tasks[taskId];
				if(task == nil)
				{
					return nil;
				}
				[task terminate];
				return nil;
			}
		};

	}
	return self;
}

#pragma FLEPlugin implementation

- (NSString *)channel 
{
	return kFlutterTaskChannelName;
}

- (nullable id)handlePlatformMessage:(NSDictionary *)message
{
	NSString *methodName = message[kPlatformMethodNameKey];
	NSDictionary *methodArgs = message[kPlatformMethodArgsKey];
	NSNumber *taskId = message[kPlatformFlutterTaskIDKey];
	ApiMethod method = _taskApiMethods[methodName];
	if(method == nil)
	{
		return nil;
	}
	return method(taskId, methodArgs);
}
@end
