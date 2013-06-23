//
//  LocationController.m
//  Tracktivity
//
//  Created by Hendrik Liebau on 15.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "TrackingManager.h"
#import "AppDelegate.h"
#import <CoreData/CoreData.h>
#import "Track+Data.h"
#import "Activity+Create.h"
#import "Segment+Create.h"
#import "Segment+Data.h"
#import "Waypoint+Create.h"
#import <RestKit/RestKit.h>

// distance filter for the location manager in meters
// use kCLDistanceFilterNone for unfiltered recording
#define DISTANCE_FILTER 5.0

// horizontal accuracy filter recording locations in meters
#define ACCURACY_FILTER 50.0

// ignore locations returned by the location manager
// that are older than this interval in seconds
#define EXPIRY_TIME_INTERVAL 10.0

@interface TrackingManager()
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *location;
@property (nonatomic) CLLocationDistance totalDistance;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) Activity *activity;
@property (nonatomic, assign, getter = isRecordingActivity) BOOL recording;
@end

@implementation TrackingManager

@synthesize locationManager = _locationManager;
@synthesize delegate = _delegate;
@synthesize recording = _recording;
@synthesize paused = _paused;
@synthesize location = _location;
@synthesize totalDistance = _totalDistance;
@synthesize context = _context;
@synthesize activity = _activity;

- (id)init
{
    self = [super init];
    if (self != nil) {
		if (![CLLocationManager locationServicesEnabled]) {
			// alert user he has to enable location services
			NSLog(@"WARNING: Location services are disabled.");
		} else {
			self.locationManager = [[CLLocationManager alloc] init];
			self.locationManager.delegate = self;
			self.locationManager.distanceFilter = DISTANCE_FILTER;
			self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
		}
		self.context = [RKManagedObjectStore.defaultStore newChildManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType tracksChanges:YES];
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
		if (!paused) {
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
		// maybe change this to multiple listeners later on
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

@end
