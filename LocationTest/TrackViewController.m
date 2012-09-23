//
//  ActivityViewController.m
//  LocationTest
//
//  Created by Hendrik Liebau on 23.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "TrackViewController.h"
#import "WaypointAnnotation.h"
#import "Activity.h"
#import "Route.h"
#import <RestKit/RestKit.h>

// minimum zoom (i.e. region width/height) in meters
#define MIN_ZOOM 250

@implementation TrackViewController

@synthesize track = _track;

- (void)createOverlay
{
	if (self.track == nil) return;
	MKPolyline *trackline = self.track.polyline;
	if (trackline) {
		[self.mapView removeOverlays:self.mapView.overlays];
		[self.mapView addOverlay:trackline];
		[self.mapView setRegion:[self adjustRectForMinimumZoomLevel:trackline.boundingMapRect onMapView:self.mapView] animated:NO];
		[self.mapView setNeedsDisplay];
	}
}

- (void)createAnnotations
{
	if (self.track == nil) return;
	[self.mapView removeAnnotations:self.mapView.annotations];
	[self.mapView addAnnotation:[WaypointAnnotation annotationForStartWaypoint:self.track.firstPoint]];
	[self.mapView addAnnotation:[WaypointAnnotation annotationForEndWaypoint:self.track.lastPoint]];
}

- (void)createOverlayAndAnnotations
{
	[self createOverlay];
	[self createAnnotations];
}

- (MKCoordinateRegion)adjustRectForMinimumZoomLevel:(MKMapRect)rect onMapView:(MKMapView *)mapView
{
	MKCoordinateRegion actualRegion = [mapView regionThatFits:MKCoordinateRegionForMapRect(rect)];
	MKCoordinateRegion minimumRegion = [mapView regionThatFits:MKCoordinateRegionMakeWithDistance(actualRegion.center, MIN_ZOOM, MIN_ZOOM)];
	if (actualRegion.span.latitudeDelta < minimumRegion.span.latitudeDelta || actualRegion.span.longitudeDelta < minimumRegion.span.longitudeDelta) {
		return minimumRegion;
	}
	return actualRegion;
}

- (void)setTrack:(Track *)track
{
	if (_track == track) return;
	_track = track;
	[self performSelector:@selector(createOverlayAndAnnotations) withObject:nil afterDelay:0];
}

- (IBAction)actionButtonPressed:(UIBarButtonItem *)sender
{
	if ([self.track isKindOfClass:[Activity class]]) {
		Activity *activity = (Activity *) self.track;
		if (activity.tracktivityID) {
			NSURL *apiURL = [RKObjectManager sharedManager].baseURL;
			NSURL *baseURL = [apiURL URLByDeletingLastPathComponent];
			NSURL *appURL = [baseURL URLByAppendingPathComponent:@"app"];
			NSString *path = [NSString stringWithFormat:@"activities/%@", activity.tracktivityID];
			[[UIApplication sharedApplication] openURL:[appURL URLByAppendingPathComponent:path]];
		}
	}
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	if ([self.track isKindOfClass:[Route class]]) {
		self.navigationItem.rightBarButtonItem = nil;
	}
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
