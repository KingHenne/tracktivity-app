//
//  LocationController.m
//  Tracktivity
//
//  Created by Hendrik Liebau on 15.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "TrackingManager.h"
#import <CoreData/CoreData.h>
#import "Track+Data.h"
#import "Activity+Create.h"
#import "Segment+Create.h"
#import "Segment+Data.h"
#import "Waypoint+Create.h"
#import "Waypoint+Strings.h"
#import <RestKit/RestKit.h>
#import <SocketRocket/SRWebSocket.h>
#import "NSURLRequest+Authorization.h"

// distance filter for the location manager in meters
// use kCLDistanceFilterNone for unfiltered recording
#define DISTANCE_FILTER 5.0

// horizontal accuracy filter recording locations in meters
#define ACCURACY_FILTER 50.0

// ignore locations returned by the location manager
// that are older than this interval in seconds
#define EXPIRY_TIME_INTERVAL 10.0

typedef enum {
    LiveTrackingFinished = 0,
    LiveTrackingPaused = 1,
    LiveTrackingRecording = 2,
	LiveTrackingStarted = 3
} LiveTrackingEvent;

@interface TrackingManager() <SRWebSocketDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *location;
@property (nonatomic) CLLocationDistance totalDistance;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) Activity *activity;
@property (nonatomic, assign, getter = isRecordingActivity) BOOL recording;
@end

@implementation TrackingManager {
	 SRWebSocket *_webSocket;
}

- (id)init
{
    self = [super init];
    if (self != nil) {
		if (![CLLocationManager locationServicesEnabled]) {
			// TODO: alert user he has to enable location services
			NSLog(@"WARNING: Location services are disabled.");
		} else {
			self.locationManager = [[CLLocationManager alloc] init];
			self.locationManager.delegate = self;
			self.locationManager.distanceFilter = DISTANCE_FILTER;
			self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
		}
		self.context = [RKManagedObjectStore.defaultStore newChildManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType tracksChanges:NO];
		_paused = YES;
		_recording = NO;
    }
    return self;
}

- (void)reset
{
	self.totalDistance = 0.0;
	self.location = nil;
}

- (void)saveContext
{
    NSError *error = nil;
	BOOL success = [self.context saveToPersistentStore:&error];
	if (!success) RKLogWarning(@"Failed saving managed object context: %@", error);
}

- (void)startActivity
{
	[self reset];
	self.activity = [self.context insertNewObjectForEntityForName:@"Activity"];
	self.activity.track = [self.context insertNewObjectForEntityForName:@"Track"];
	self.activity.recording = [NSNumber numberWithBool:YES];
	self.activity.start = [NSDate date];
	self.recording = YES;
	self.paused = NO;
	[self startLiveTracking];
	if ([self.delegate respondsToSelector:@selector(startedActivity)]) {
		[self.delegate startedActivity];
	}
}

- (void)finishActivity
{
	self.paused = YES;
	self.recording = NO;
	if (self.activity.track.numberOfTotalPoints < 2) {
		[self.context deleteObject:self.activity];
		self.activity = nil;
	} else {
		self.activity.end = [NSDate date];
		self.activity.recording = [NSNumber numberWithBool:NO];
	}
	[self saveContext];
	[self finishLiveTracking];
	if ([self.delegate respondsToSelector:@selector(finishedActivity)]) {
		[self.delegate finishedActivity];
	}
}

- (void)setPaused:(BOOL)paused
{
	_paused = paused;
	if (!paused && !self.isRecordingActivity) {
		[self startActivity];
	} else {
		if (paused) {
			[self pauseLiveTracking];
		} else {
			[self.activity.track addSegmentsObject:[self.context insertNewObjectForEntityForName:@"Segment"]];
			[self.locationManager startUpdatingLocation];
		}
		if ([self.delegate respondsToSelector:@selector(toggledPause:)]) {
			[self.delegate toggledPause:paused];
		}
	}
}

- (void)recordLocation:(CLLocation *)newLocation
{
	if (self.location) {
		self.totalDistance += [newLocation distanceFromLocation:self.location];
	}
	self.location = newLocation;
	Waypoint *newPoint = [Waypoint waypointWithLocation:newLocation inManagedObjectContext:self.context];
	[self.activity.track.segments.lastObject addPointsObject:newPoint];
	[self doLiveTrackingWithPoint:newPoint];
}

- (void)togglePause
{
	self.paused = !self.isPaused;
}

- (void)startUpdatingWithoutRecording
{
	if (self.isPaused) {
		[self.locationManager startUpdatingLocation];
	}
}

- (void)stopUpdatingWithoutRecording
{
	if (self.isPaused) {
		[self.locationManager stopUpdatingLocation];
	}
}

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation
{
	NSTimeInterval howRecent = [newLocation.timestamp timeIntervalSinceNow];
	if (abs(howRecent) < EXPIRY_TIME_INTERVAL) {
		if (self.isRecordingActivity && !self.isPaused && newLocation.horizontalAccuracy < ACCURACY_FILTER) {
			[self recordLocation:newLocation];
		}
		// publish location update to current delegate
		// maybe change this to multiple listeners later on, or use GCD
		if ([self.delegate respondsToSelector:@selector(locationUpdate:)]) {
			[self.delegate locationUpdate:newLocation];
		}
	}
}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
	NSLog(@"ERROR: %@", error);
	if ([self.delegate respondsToSelector:@selector(locationUpdateFailedWithError:)]) {
		[self.delegate locationUpdateFailedWithError:error];
	}
}

+ (TrackingManager *)sharedTrackingManager
{
	static TrackingManager *sharedTrackingManagerInstance = nil;
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
		sharedTrackingManagerInstance = [[self alloc] init];
	});
	return sharedTrackingManagerInstance;
}

#pragma mark SRWebSocketDelegate implementation

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
	NSLog(@"WebSocket opened");
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
{
    NSLog(@"WebSocket failed with error %@", error);
    _webSocket.delegate = nil;
    _webSocket = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
	NSLog(@"WebSocket closed, code: %d, reason: %@, wasClean: %d", code, reason, wasClean);
    _webSocket.delegate = nil;
	_webSocket = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
	NSLog(@"received WebSocket message: %@", message);
}

#pragma mark Live Tracking

- (void)startLiveTracking
{
	NSURLRequest *urlRequest = [NSURLRequest requestWithURLString:@"wss://henlie.sinnerschrader.it:8443/live"
														 username:@"hendrik" password:@"123456"];
	_webSocket.delegate = nil;
    [_webSocket close];
    
    _webSocket = [[SRWebSocket alloc] initWithURLRequest:urlRequest];
    _webSocket.delegate = self;
    
	NSLog(@"Opening WebSocket ...");
    [_webSocket open];
	
	[self sendDataAsJSONviaWebSocket:@{@"event": [NSNumber numberWithInt:LiveTrackingStarted],
									   @"time":  RKStringFromDate(self.activity.start)}];
}

- (void)pauseLiveTracking
{
	[self sendDataAsJSONviaWebSocket:@{@"event": [NSNumber numberWithInt:LiveTrackingPaused],
									   @"time":  RKStringFromDate([NSDate date])}];
}

- (void)finishLiveTracking
{
	NSDate *date = [NSDate date];
	if (self.activity) {
		date = self.activity.end;
	}
	[self sendDataAsJSONviaWebSocket:@{@"event": [NSNumber numberWithInt:LiveTrackingFinished],
									   @"time":  RKStringFromDate(date)}];
    [_webSocket close];
}

- (void)doLiveTrackingWithPoint:(Waypoint *)point
{
	NSDictionary *pointDict = [RKObjectParameterization parametersWithObject:point
														   requestDescriptor:self.waypointRequestDescriptor
																	   error:nil];
	[self sendDataAsJSONviaWebSocket:@{@"event": [NSNumber numberWithInt:LiveTrackingRecording],
									   @"point": pointDict}];
}

- (void)sendDataAsJSONviaWebSocket:(NSDictionary *)data
{
	NSError *error;
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
	if (jsonData) {
		NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
		// FIXME: Invalid State: Cannot call send: until connection is open
		// TODO: what to do? use a custom queue here?
		[_webSocket send:jsonString];
	} else {
		NSLog(@"Error while serializing: %@", error);
	}
}

@end
