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

// default zoom (i.e. region width/height) in meters
#define DEFAULT_ZOOM 500

#define BTN_RECORD_START NSLocalizedString(@"RecordButtonStart", @"record button label for start action")
#define BTN_RECORD_STOP NSLocalizedString(@"RecordButtonStop", @"record button label for stop action")

@interface RecordViewController ()
@property (nonatomic, weak) IBOutlet UIButton *recordButton;
@property (nonatomic, strong) NSMutableArray *waypoints;
@property (nonatomic, strong) MKPolyline *polyline;
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
		//[self centerMapOnLocation:self.trackingManager.location];
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
	[self.trackingManager toggleRecording];
}

- (void)setRecordButtonTitle:(BOOL)recording
{
	if (self.view.window) {
		NSString *buttonTitle = recording ? BTN_RECORD_STOP : BTN_RECORD_START;
		[self.recordButton setTitle:buttonTitle forState:UIControlStateNormal];
	}
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
	MKPolyline *oldPolyline = self.polyline;
	self.polyline = self.trackingManager.polyline;
	if (self.polyline) {
		[self.mapView addOverlay:self.polyline];
		[self.mapView setNeedsDisplay];
	}
	if (oldPolyline) [self.mapView removeOverlay:oldPolyline];
}

#pragma mark TrackingManagerDelegate Methods

- (void)locationUpdate:(CLLocation *)location
{
	if (self.trackingManager.recording) {
		if (!self.waypoints.count) {
			WaypointAnnotation *startAnnotation = [WaypointAnnotation annotationForStartLocation:location];
			[self.waypoints addObject:startAnnotation];
			[self.mapView addAnnotation:startAnnotation];
		}
		[self updateTrackOverlay];
	}
	self.userLocation.coordinate = location.coordinate;
	if (self.automaticallyCenterMapOnUser) {
		[self centerMapOnLocation:location];
	}
}

- (void)toggledRecording:(BOOL)recording
{
	if (self.view.window) {
		[self setRecordButtonTitle:recording];
		if (recording) {
			// Add start waypoint to the map.
			[self.mapView removeAnnotations:self.waypoints];
			[self.waypoints removeAllObjects];
		} else {
			// Add end waypoint to the map.
			WaypointAnnotation *endAnnotation = [WaypointAnnotation annotationForEndLocation:self.trackingManager.location];
			[self.waypoints addObject:endAnnotation];
			[self.mapView addAnnotation:endAnnotation];
			[self.mapView selectAnnotation:endAnnotation animated:YES];
		}
	}
	[self setRecordingBadge:recording];
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

#pragma mark UIViewController Methods

- (void)viewWillAppear:(BOOL)animated
{
	self.trackingManager.delegate = self;
	[self.trackingManager startUpdatingWithoutRecording];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	[self.trackingManager stopUpdatingWithoutRecording];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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
