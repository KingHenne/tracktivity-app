//
//  FirstViewController.m
//  LocationTest
//
//  Created by Hendrik Liebau on 14.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "RecordViewController.h"
#import <MapKit/MKUserLocation.h>
#import <MapKit/MKPinAnnotationView.h>
#import "WaypointAnnotation.h"
#import "WildcardGestureRecognizer.h"
#import "UserLocationAnnotation.h"
#import "Segment+Data.h"

// default zoom (i.e. region width/height) in meters
#define DEFAULT_ZOOM 500

#define BTN_RECORD_START NSLocalizedString(@"RecordButtonStart", @"record button label for start action")
#define BTN_RECORD_PAUSE NSLocalizedString(@"RecordButtonPause", @"record button label for pause action")
#define BTN_RECORD_CONTINUE NSLocalizedString(@"RecordButtonContinue", @"record button label for continue action")

@interface RecordViewController ()
@property (nonatomic, weak) IBOutlet UIButton *recordButton;
@property (nonatomic, weak) IBOutlet UIButton *finishButton;
@property (nonatomic, strong) NSMutableArray *waypoints;
@property (nonatomic, strong) MKPolyline *polyline;
@property (nonatomic, strong) Segment *currentSegment;
@property (nonatomic, strong, readonly) TrackingManager *trackingManager;
@property (nonatomic) BOOL automaticallyCenterMapOnUser;
@property (weak, nonatomic) IBOutlet UIButton *centerLocationButton;
@property (nonatomic, strong) UserLocationAnnotation *userLocation;
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
		[self.centerLocationButton setTitleColor:[UIColor colorWithRed:0 green:0.45f blue:0.9f alpha:0.8f] forState:UIControlStateNormal];
	} else {
		[self.centerLocationButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
	}
}

- (void)centerMapOnLocation:(CLLocation *)location
{
	MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location.coordinate, DEFAULT_ZOOM, DEFAULT_ZOOM);
	[self.mapView setRegion:region animated:YES];
}

- (IBAction)recordButtonPressed:(UIButton *)sender
{
	if (self.trackingManager.isRecordingActivity) {
		[self.trackingManager togglePause];
		if (self.trackingManager.isPaused) {
			[self setRecordButtonTitle:BTN_RECORD_CONTINUE];
		} else {
			[self setRecordButtonTitle:BTN_RECORD_PAUSE];
		}
	} else {
		[self.trackingManager startActivity];
		[self setRecordButtonTitle:BTN_RECORD_PAUSE];
		self.finishButton.alpha = 1;
	}
}

- (IBAction)finishButtonPressed:(UIButton *)sender
{
	self.finishButton.alpha = 0;
	[self setRecordButtonTitle:BTN_RECORD_START];
	[self.trackingManager finishActivity];
}

- (void)setRecordButtonTitle:(NSString *)title
{
	[self.recordButton setTitle:title forState:UIControlStateNormal];
}

- (IBAction)locationCenterButtonPressed:(UIButton *)sender
{
	self.automaticallyCenterMapOnUser = !self.automaticallyCenterMapOnUser;
}

- (void)setRecordingBadge:(BOOL)recording
{
	self.tabBarItem.badgeValue = recording ? @"Rec" : nil;
}

- (void)updateTrackOverlay
{
	Segment *lastSegment = self.trackingManager.activity.segments.lastObject;
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

- (void)startedActivity
{
	[self.mapView removeAnnotations:self.waypoints];
	[self.waypoints removeAllObjects];
	[self.mapView removeOverlays:self.mapView.overlays];
	[self setRecordingBadge:YES];
}

- (void)finishedActivity
{
	[self setRecordingBadge:NO];
	// Add end waypoint to the map.
	WaypointAnnotation *endAnnotation = [WaypointAnnotation annotationForEndLocation:self.trackingManager.location];
	[self.waypoints addObject:endAnnotation];
	[self.mapView addAnnotation:endAnnotation];
	[self.mapView selectAnnotation:endAnnotation animated:YES];
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

- (void)viewDidAppear
{
	self.trackingManager.delegate = self;
	[self.trackingManager startUpdatingWithoutRecording];
	if (self.trackingManager.isPaused) {
		self.mapView.showsUserLocation = YES;
	}
}

- (void)appDidBecomeActiveNotification:(NSNotification *)notification
{
	if (self.view.window) {
		[self viewDidAppear];
	}
}

#pragma mark UIViewController Methods

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self viewDidAppear];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(appDidBecomeActiveNotification:)
												 name:UIApplicationDidBecomeActiveNotification
											   object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	[self.trackingManager stopUpdatingWithoutRecording];
	self.mapView.showsUserLocation = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.finishButton.alpha = 0;
	self.automaticallyCenterMapOnUser = YES;
	WildcardGestureRecognizer * tapInterceptor = [[WildcardGestureRecognizer alloc] init];
	tapInterceptor.touchesBeganCallback = ^(NSSet * touches, UIEvent * event) {
        self.automaticallyCenterMapOnUser = NO;
	};
	[self.mapView addGestureRecognizer:tapInterceptor];
}

- (void)viewDidUnload
{
	[self setRecordButton:nil];
	[self setFinishButton:nil];
	[self setCenterLocationButton:nil];
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
