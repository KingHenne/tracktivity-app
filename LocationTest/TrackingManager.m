//
//  LocationController.m
//  LocationTest
//
//  Created by Hendrik Liebau on 15.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "TrackingManager.h"
#import "AppDelegate.h"
#import <CoreData/CoreData.h>
#import "Activity+Create.h"
#import "Segment+Create.h"
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
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *stopTime;
@property (nonatomic, strong) NSMutableArray *locations;
@property (nonatomic) CLLocationDistance totalDistance;
@property (nonatomic, strong) NSManagedObjectContext *context;
@end

@implementation TrackingManager

@synthesize locationManager = _locationManager;
@synthesize delegate = _delegate;
@synthesize recording = _recording;
@synthesize location = _location;
@synthesize startTime = _startTime;
@synthesize stopTime = _stopTime;
@synthesize locations = _locations;
@synthesize totalDistance = _totalDistance;
@synthesize context = _context;

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
		}
		self.context = [NSManagedObjectContext contextForCurrentThread];
    }
    return self;
}

- (void)reset
{
	self.stopTime = nil;
	self.totalDistance = 0.0;
	self.location = nil;
	[self.locations removeAllObjects];
}

- (void)saveActivity
{
	if (self.locations.count <= 1) return;
	Activity *activity = [Activity activityWithStart:self.startTime end:self.stopTime inManagedObjectContext:self.context];
	Segment *segment = [Segment segmentWithLocations:self.locations inManagedObjectContext:self.context];
	[activity addSegmentsObject:segment];
	[self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
	if (![RKManagedObjectStore.defaultObjectStore save:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
}

- (void)startUpdatingWithoutRecording
{
	if (!self.recording) {
		self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
		[self.locationManager startUpdatingLocation];
	}
}

- (void)stopUpdatingWithoutRecording
{
	if (!self.recording) {
		[self.locationManager stopUpdatingLocation];
	}
}

- (void)setRecording:(BOOL)recording
{
	if (_recording != recording) {
		_recording = recording;
		if (_recording) {
			[self reset];
			self.startTime = [NSDate date];
			self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
			[self.locationManager startUpdatingLocation];
		} else {
			self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
			self.stopTime = [NSDate date];
			[self saveActivity];
		}
		if ([self.delegate respondsToSelector:@selector(toggledRecording:)]) {
			[self.delegate toggledRecording:_recording];
		}
	}
}

- (NSMutableArray *)locations
{
	if (_locations == nil) { // lazy instantiation
		_locations = [[NSMutableArray alloc] init];
	}
	return _locations;
}

- (void)recordLocation:(CLLocation *)newLocation
{
	if (self.location) {
		self.totalDistance += [newLocation distanceFromLocation:self.location];
	}
	self.location = newLocation;
	[self.locations addObject:newLocation];
}

- (MKPolyline *)polyline
{
	MKPolyline *polyline;
	int numPoints = self.locations.count;
	if (numPoints > 1)
	{
		CLLocationCoordinate2D* coords = malloc(numPoints * sizeof(CLLocationCoordinate2D));
		for (int i = 0; i < numPoints; i++)
		{
			CLLocation* current = [self.locations objectAtIndex:i];
			coords[i] = current.coordinate;
		}
		polyline = [MKPolyline polylineWithCoordinates:coords count:numPoints];
		free(coords);
	}
	return polyline;
}

- (void)toggleRecording
{
	self.recording = !self.recording;
}

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation
{
	NSTimeInterval howRecent = [newLocation.timestamp timeIntervalSinceNow];
	if (abs(howRecent) < EXPIRY_TIME_INTERVAL) {
		if (self.recording && newLocation.horizontalAccuracy < ACCURACY_FILTER) {
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
