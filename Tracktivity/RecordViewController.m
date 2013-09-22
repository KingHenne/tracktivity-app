//
//  FirstViewController.m
//  Tracktivity
//
//  Created by Hendrik Liebau on 14.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "RecordViewController.h"
#import <MapKit/MKUserLocation.h>
#import <MapKit/MKPinAnnotationView.h>
#import <MapKit/MKPolylineView.h>
#import "WaypointAnnotation.h"
#import "WildcardGestureRecognizer.h"
#import "UserLocationAnnotation.h"
#import "Segment+Data.h"
#import "WrappedTrackHandler.h"
#import "Track+Data.h"
#import "FinishActivityViewController.h"
#import <RestKit/RestKit.h>
#import "TrackViewController.h"

// default zoom (i.e. region width/height) in meters
#define DEFAULT_ZOOM 500

#define BTN_RECORD_START NSLocalizedString(@"RecordButtonStart", @"record button label for start action")
#define BTN_RECORD_PAUSE NSLocalizedString(@"RecordButtonPause", @"record button label for pause action")
#define BTN_RECORD_CONTINUE NSLocalizedString(@"RecordButtonContinue", @"record button label for continue action")

@interface RecordViewController ()
@property (nonatomic, weak) IBOutlet UIBarButtonItem *recordButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *finishButton;
@property (nonatomic, strong) NSMutableArray *waypoints;
@property (nonatomic, strong) MKPolyline *polyline;
@property (nonatomic, strong) Segment *currentSegment;
@property (nonatomic, strong, readonly) TrackingManager *trackingManager;
@property (nonatomic) BOOL automaticallyCenterMapOnUser;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *centerLocationButton;
@property (nonatomic, strong) UserLocationAnnotation *userLocation;
@property (nonatomic, strong) WrappedTrack *backgroundTrack;
@property (nonatomic, strong) MultiPolyline *backgroundTrackMultiPolyline;
@end

@implementation RecordViewController

@synthesize recordButton = _recordButton;
@synthesize trackingManager = _trackingManager;
@synthesize waypoints = _waypoints;
@synthesize polyline = _polyline;
@synthesize currentSegment = _currentSegment;
@synthesize automaticallyCenterMapOnUser = _automaticallyCenterMapOnUser;
@synthesize centerLocationButton = _centerLocationButton;
@synthesize userLocation = _userLocation;
@synthesize backgroundTrack = _backgroundTrack;
@synthesize backgroundTrackMultiPolyline = _backgroundTrackMultiPolyline;

- (TrackingManager *)trackingManager
{
	if (_trackingManager == nil) {
		_trackingManager = [TrackingManager sharedTrackingManager];
		_trackingManager.delegate = self;
	}
	return _trackingManager;
}

- (NSMutableArray *)waypoints
{
	if (_waypoints == nil) { // lazy instantiation
		_waypoints = [NSMutableArray array];
	}
	return _waypoints;
}

- (void)setUserLocation:(UserLocationAnnotation *)userLocation
{
	if (self.mapView) {
		[self.mapView addAnnotation:userLocation];
	}
	_userLocation = userLocation;
}

- (UserLocationAnnotation *)userLocation
{
	if (_userLocation == nil) { // lazy instantiation
		self.userLocation = [UserLocationAnnotation new];
	}
	return _userLocation;
}

- (void)setBackgroundTrack:(WrappedTrack *)backgroundTrack
{
	_backgroundTrack = backgroundTrack;
	self.backgroundTrackMultiPolyline = backgroundTrack.track.multiPolyline;
}

- (void)setBackgroundTrackMultiPolyline:(MultiPolyline *)backgroundTrackMultiPolyline
{
	if (_backgroundTrackMultiPolyline) {
		[self.mapView removeOverlays:_backgroundTrackMultiPolyline.polylines];
	}
	_backgroundTrackMultiPolyline = backgroundTrackMultiPolyline;
	if (_backgroundTrackMultiPolyline) {
		[self.mapView addOverlays:_backgroundTrackMultiPolyline.polylines];
	}
}

- (void)setAutomaticallyCenterMapOnUser:(BOOL)center
{
	_automaticallyCenterMapOnUser = center;
	if (center) {
		if (self.view.window) {
			if (self.trackingManager.isPaused) {
				[self centerMapOnLocation:self.mapView.userLocation.location];
			} else {
				[self centerMapOnLocation:self.trackingManager.location];
			}
		}
		self.centerLocationButton.tintColor = [UIColor whiteColor];
	} else {
		self.centerLocationButton.tintColor = [UIColor darkGrayColor];
	}
}

- (void)centerMapOnLocation:(CLLocation *)location
{
	if (location == nil) return;
	MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location.coordinate, DEFAULT_ZOOM, DEFAULT_ZOOM);
	[self.mapView setRegion:region animated:YES];
}

- (IBAction)recordButtonPressed:(UIBarButtonItem *)sender
{
	if (self.trackingManager.isRecordingActivity) {
		[self.trackingManager togglePause];
		if (self.trackingManager.isPaused) {
			self.recordButton.title = BTN_RECORD_CONTINUE;
		} else {
			self.recordButton.title = BTN_RECORD_PAUSE;
		}
	} else {
		[self.trackingManager startActivity];
		self.recordButton.title = BTN_RECORD_PAUSE;
		self.finishButton.enabled = YES;
	}
}

- (IBAction)finishButtonPressed:(UIBarButtonItem *)sender
{
	self.finishButton.enabled = NO;
	self.recordButton.title = BTN_RECORD_START;
	[self.trackingManager finishActivity];
}

- (IBAction)locationCenterButtonPressed:(UIBarButtonItem *)sender
{
	self.automaticallyCenterMapOnUser = !self.automaticallyCenterMapOnUser;
}

- (void)setRecordingBadge:(BOOL)recording
{
	self.tabBarItem.badgeValue = recording ? @"Rec" : nil;
}

- (void)updateTrackOverlay
{
	Segment *lastSegment = self.trackingManager.activity.track.segments.lastObject;
	MKPolyline *polyline = lastSegment.polyline;
	if (polyline) {
		[self.mapView addOverlay:polyline];
		[self.mapView setNeedsDisplay];
	}
	if (self.currentSegment == lastSegment && self.polyline) {
		[self.mapView removeOverlay:self.polyline];
	}
	self.currentSegment = lastSegment;
	self.polyline = polyline;
}

#pragma mark TrackingManagerDelegate Methods

- (void)locationUpdate:(CLLocation *)location
{
	if (self.trackingManager.isRecordingActivity && !self.trackingManager.isPaused) {
		if (!self.waypoints.count) {
			// Add start waypoint to the map.
			WaypointAnnotation *startAnnotation = [WaypointAnnotation annotationForStartLocation:location];
			[self.waypoints addObject:startAnnotation];
			[self.mapView addAnnotation:startAnnotation];
		}
		[self updateTrackOverlay];
		self.userLocation.coordinate = location.coordinate;
		if (![self.mapView.annotations containsObject:self.userLocation]) {
			[self.mapView addAnnotation:self.userLocation];
		}
	}
	if (self.automaticallyCenterMapOnUser) {
		[self centerMapOnLocation:location];
	}
}

- (void)reset
{
	[self.mapView removeAnnotations:self.waypoints];
	[self.waypoints removeAllObjects];
	if (self.backgroundTrackMultiPolyline) {
		// remove all overlays not belonging to the background track
		NSMutableArray *mapOverlays = [self.mapView.overlays mutableCopy];
		[mapOverlays removeObjectsInArray:self.backgroundTrackMultiPolyline.polylines];
		[self.mapView removeOverlays:mapOverlays];
	} else {
		// remove all overlays
		[self.mapView removeOverlays:self.mapView.overlays];
	}
}

- (void)startedActivity
{
	[self reset];
	[self setRecordingBadge:YES];
}

- (void)finishedActivity
{
	[self setRecordingBadge:NO];
	if (self.trackingManager.activity) {
		// Add end waypoint to the map.
		Waypoint *lastPoint = self.trackingManager.activity.track.lastPoint;
		WaypointAnnotation *endAnnotation = [WaypointAnnotation annotationForEndWaypoint:lastPoint];
		[self.waypoints addObject:endAnnotation];
		[self.mapView addAnnotation:endAnnotation];
		[self.mapView selectAnnotation:endAnnotation animated:YES];
		[self performSelector:@selector(showFinishActivityView) withObject:nil afterDelay:1];
	} else {
		[self.mapView removeAnnotations:self.waypoints];
	}
}

- (void)showFinishActivityView
{
	[self performSegueWithIdentifier:@"Finish Activity" sender:self];
}

- (void)toggledPause:(BOOL)paused
{
	if (paused) {
		[self.mapView removeAnnotation:self.userLocation];
		self.mapView.showsUserLocation = YES;
		self.polyline = nil;
	} else {
		self.mapView.showsUserLocation = NO;
	}
}

- (void)saveContext
{
	NSError *error = nil;
	BOOL success = [RKManagedObjectStore.defaultStore.mainQueueManagedObjectContext saveToPersistentStore:&error];
	if (!success) RKLogWarning(@"Failed saving managed object context: %@", error);
}

#pragma mark MKMapViewDelegate Methods

- (MKAnnotationView *)mapView:(MKMapView *)mapView
			viewForAnnotation:(id<MKAnnotation>)annotation
{
	if ([annotation isKindOfClass:[UserLocationAnnotation class]]) {
		// Try to dequeue an existing view first.
		MKAnnotationView *aView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"UserLocationAnnotationView"];
		if (!aView) {
			// If an existing view was not available, create one.
			aView = [[MKAnnotationView alloc] initWithAnnotation:annotation
												 reuseIdentifier:@"UserLocationAnnotationView"];
			aView.image = [UIImage imageNamed:@"userLocation.png"];
			aView.centerOffset = CGPointMake(1, 0);
			aView.canShowCallout = NO;
		}
		return aView;
	}
	return [super mapView:mapView viewForAnnotation:annotation];
}

- (MKOverlayView *)mapView:(MKMapView *)theMapView
			viewForOverlay:(id <MKOverlay>)overlay
{
	MKPolylineView* lineView = [[MKPolylineView alloc] initWithPolyline:overlay];
	if ([self.backgroundTrackMultiPolyline.polylines containsObject:overlay]) {
		lineView.strokeColor = [UIColor colorWithRed:0.13f green:0.73f blue:0.19f alpha:0.7f];
	} else {
		lineView.strokeColor = [UIColor colorWithRed:0 green:0.45f blue:0.9f alpha:0.8f];
	}
	return lineView;
}

- (void)viewDidAppear
{
	self.trackingManager.delegate = self;
	[self.trackingManager startUpdatingWithoutRecording];
	if (self.trackingManager.isPaused) {
		self.mapView.showsUserLocation = YES;
	} else {
		[self.mapView setNeedsDisplay];
	}
}

- (void)stopUsingLocationServices
{
	[self.trackingManager stopUpdatingWithoutRecording];
	self.mapView.showsUserLocation = NO;
}

- (void)appDidBecomeActiveNotification:(NSNotification *)notification
{
	if (self.view.window) {
		[self viewDidAppear];
	}
}

- (void)appDidEnterBackgroundNotification:(NSNotification *)notification
{
	[self stopUsingLocationServices];
}

- (void)backgroundTrackRequestedNotification:(NSNotification *)notification
{
	if (!self.trackingManager.isRecordingActivity) {
		self.backgroundTrack = [notification object];
	}
}

#pragma mark FinishActivityViewControllerPresenter Methods

- (void)finishActivityViewController:(FinishActivityViewController *)sender
				   didFinishActivity:(Activity *)activity
{
	[self dismissViewControllerAnimated:YES completion:^{
	}];
}

- (void)finishActivityViewController:(FinishActivityViewController *)sender
					didAbortActivity:(Activity *)activity
{
	__block __typeof__(self) blockSelf = self;
	[self dismissViewControllerAnimated:YES completion:^{
		[activity.managedObjectContext deleteObject:activity];
		[blockSelf saveContext];
		[blockSelf reset];
	}];
}

#pragma mark UIViewController Methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"Finish Activity"]) {
		UINavigationController *modalNavController = (UINavigationController *) segue.destinationViewController;
		FinishActivityViewController *finishViewController = (FinishActivityViewController *) modalNavController.topViewController;
		finishViewController.wrappedTrack = self.trackingManager.activity;
		finishViewController.delegate = self;
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self viewDidAppear];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(appDidBecomeActiveNotification:)
												 name:UIApplicationDidBecomeActiveNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(appDidEnterBackgroundNotification:)
												 name:UIApplicationDidEnterBackgroundNotification
											   object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
	[self stopUsingLocationServices];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.finishButton.enabled = NO;
	self.automaticallyCenterMapOnUser = YES;
	WildcardGestureRecognizer * tapInterceptor = [[WildcardGestureRecognizer alloc] init];
	tapInterceptor.touchesBeganCallback = ^(NSSet * touches, UIEvent * event) {
        self.automaticallyCenterMapOnUser = NO;
	};
	[self.mapView addGestureRecognizer:tapInterceptor];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(backgroundTrackRequestedNotification:)
												 name:BackgroundTrackRequestedNotification
											   object:nil];
}

- (void)viewDidUnload
{
	[self setRecordButton:nil];
	[self setFinishButton:nil];
	[self setCenterLocationButton:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BackgroundTrackRequestedNotification object:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	} else {
	    return YES;
	}
}

@end
