//
//  MapViewController.m
//  Tracktivity
//
//  Created by Hendrik Liebau on 15.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <MapKit/MKPinAnnotationView.h>
#import <MapKit/MKPolylineView.h>
#import "MapViewController.h"
#import "WaypointAnnotation.h"

@implementation MapViewController

@synthesize mapView = _mapView;

#pragma mark MKMapViewDelegate Methods

- (MKAnnotationView *)mapView:(MKMapView *)mapView
			viewForAnnotation:(id<MKAnnotation>)annotation
{
	if ([annotation isKindOfClass:[WaypointAnnotation class]]) {
		WaypointAnnotation *wpa = (WaypointAnnotation *)annotation;
		// Try to dequeue an existing view first.
		MKPinAnnotationView *pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"WaypointAnnotationView"];
		if (!pinView) {
			// If an existing view was not available, create one.
			pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
													  reuseIdentifier:@"WaypointAnnotationView"];
			pinView.animatesDrop = YES;
			pinView.canShowCallout = YES;
		} else {
			pinView.annotation = annotation;
		}
		
		// Set the pin color based on the waypoint index.
		switch (wpa.index) {
			case kWaypointAnnotationStart:
				pinView.pinColor = MKPinAnnotationColorGreen;
				break;
			case kWaypointAnnotationEnd:
				pinView.pinColor = MKPinAnnotationColorRed;
				break;
			default:
				pinView.pinColor = MKPinAnnotationColorPurple;
				break;
		}
		
		return pinView;
	}
	return nil;
}

- (MKOverlayView *)mapView:(MKMapView *)theMapView
			viewForOverlay:(id <MKOverlay>)overlay
{
	MKPolylineView* lineView = [[MKPolylineView alloc] initWithPolyline:overlay];
	lineView.strokeColor = [UIColor colorWithRed:0 green:0.45f blue:0.9f alpha:0.8f];
	// Compute the currently visible map zoom scale
	//MKZoomScale currentZoomScale = (CGFloat)(theMapView.bounds.size.width / theMapView.visibleMapRect.size.width);
	// Find out the line width at this zoom scale to set it as width for the lineView.
	//lineView.lineWidth = MKRoadWidthAtZoomScale(currentZoomScale);
	//lineView.lineWidth = 10;
	return lineView;
}

- (void)viewDidUnload
{
	self.mapView.delegate = nil;
	[self setMapView:nil];
    [super viewDidUnload];
}

@end
