//
//  ActivityViewController.m
//  Tracktivity
//
//  Created by Hendrik Liebau on 23.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "TrackViewController.h"
#import "WaypointAnnotation.h"
#import "Activity.h"
#import "Route.h"
#import <RestKit/RestKit.h>
#import "Track+Data.h"
#import "WrappedTrack+Info.h"
#import "OpenInSafariActivity.h"

#define IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
// minimum zoom (i.e. region width/height) in meters
#define MIN_ZOOM (IPAD ? 600 : 250)

NSString * const BackgroundTrackRequestedNotification = @"BackgroundTrackRequestedNotification";

@interface TrackViewController () <UIActionSheetDelegate>
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) NSURL *tracktivityURL;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *actionButton;
@end

@implementation TrackViewController

@synthesize wrappedTrack = _wrappedTrack;
@synthesize splitViewBarButtonItem = _splitViewBarButtonItem;
@synthesize popoverController = _myPopoverController;
@synthesize actionSheet = _actionSheet;
@synthesize tracktivityURL = _tracktivityURL;

- (void)setSplitViewBarButtonItem:(UIBarButtonItem *)splitViewBarButtonItem
{
	if (_splitViewBarButtonItem == splitViewBarButtonItem) return;
	self.navigationItem.leftBarButtonItem = splitViewBarButtonItem;
	_splitViewBarButtonItem = splitViewBarButtonItem;
}

- (NSURL *)tracktivityURL
{
	if (_tracktivityURL == nil && [self.wrappedTrack respondsToSelector:@selector(tracktivityID)]) {
		NSString *tracktivityID = [self.wrappedTrack performSelector:@selector(tracktivityID)];
		if (tracktivityID) {
			NSURL *apiURL = [RKObjectManager sharedManager].baseURL;
			NSURL *baseURL = [apiURL URLByDeletingLastPathComponent];
			NSURL *appURL = [baseURL URLByAppendingPathComponent:@"app"];
			NSString *path = [NSString stringWithFormat:@"activities/%@", tracktivityID];
			_tracktivityURL = [appURL URLByAppendingPathComponent:path];
		}
	}
	return _tracktivityURL;
}

- (void)createOverlays
{
	if (self.wrappedTrack == nil) return;
	MultiPolyline *multiPolyline = self.wrappedTrack.track.multiPolyline;
	if (multiPolyline) {
		[self.mapView removeOverlays:self.mapView.overlays];
		MKMapRect unionRect = MKMapRectNull;
		for (MKPolyline *polyline in multiPolyline.polylines) {
			[self.mapView addOverlay:polyline];
			unionRect = MKMapRectUnion(unionRect, polyline.boundingMapRect);
		}
		// add a little padding
		UIEdgeInsets padding = UIEdgeInsetsMake(40, 20, 20, 20);
		if (IPAD) {
			padding = UIEdgeInsetsMake(60, 40, 40, 40);
		}
		MKMapRect paddedRect = [self.mapView mapRectThatFits:unionRect edgePadding:padding];
		// stay above minimum zoom level
		MKCoordinateRegion adjustedRegion = [self adjustRectForMinimumZoomLevel:paddedRect onMapView:self.mapView];
		if (IPAD) {
			[self.mapView setRegion:adjustedRegion animated:YES];
		} else {
			[self.mapView setRegion:adjustedRegion animated:NO];
		}
		[self.mapView setNeedsDisplay];
	}
}

- (void)createAnnotations
{
	if (self.wrappedTrack == nil) return;
	[self.mapView removeAnnotations:self.mapView.annotations];
	[self.mapView addAnnotation:[WaypointAnnotation annotationForStartWaypoint:self.wrappedTrack.track.firstPoint]];
	[self.mapView addAnnotation:[WaypointAnnotation annotationForEndWaypoint:self.wrappedTrack.track.lastPoint]];
	[self.mapView setNeedsDisplay];
}

- (void)createOverlaysAndAnnotations
{
	[self createOverlays];
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

- (void)setWrappedTrack:(WrappedTrack *)wrappedTrack
{
	if (_wrappedTrack == wrappedTrack) return;
	if (self.navigationItem.rightBarButtonItem == nil) {
		self.navigationItem.rightBarButtonItem = self.actionButton;
	}
	_wrappedTrack = wrappedTrack;
	self.title = wrappedTrack.title;
	self.tracktivityURL = nil; // reset saved URL
	//[self createOverlaysAndAnnotations];
	[self performSelector:@selector(createOverlaysAndAnnotations) withObject:nil afterDelay:0];
}

- (IBAction)actionButtonPressed:(UIBarButtonItem *)sender
{
	if ([UIActivityViewController class]) {
		NSArray *items = [NSArray arrayWithObjects:self.tracktivityURL, nil];
		NSArray *customActivities = [NSArray arrayWithObject:[OpenInSafariActivity new]];
		UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:customActivities];
		if (IPAD) {
			if (self.popoverController.popoverVisible) {
				[self.popoverController dismissPopoverAnimated:YES];
			} else {
				self.popoverController = [[UIPopoverController alloc] initWithContentViewController:activityVC];
				[self.popoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			}
		} else {
			[self presentModalViewController:activityVC animated:YES];
		}
	} else {
		if (self.actionSheet) return;
		NSString *cancelButtonTitle = NSLocalizedString(@"ActionSheetCancel", @"action sheet cancel button label");
		NSString *bgtrackButtonTitle = NSLocalizedString(@"ActionSheetBackgroundTrack", @"action sheet button label background track");
		if (self.tracktivityURL) {
			NSString *safariButtonTitle = NSLocalizedString(@"ActionSheetOpenInSafari", @"action sheet button label open in safari");
			self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:cancelButtonTitle destructiveButtonTitle:nil otherButtonTitles:bgtrackButtonTitle, safariButtonTitle, nil];
		} else {
			self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:cancelButtonTitle destructiveButtonTitle:nil otherButtonTitles:bgtrackButtonTitle, nil];
		}
		[self.actionSheet showFromBarButtonItem:sender animated:YES];
	}
}

#pragma mark UIActionSheetDelegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == actionSheet.firstOtherButtonIndex) {
		[[NSNotificationCenter defaultCenter] postNotificationName:BackgroundTrackRequestedNotification object:self.wrappedTrack];
	} else if (buttonIndex == actionSheet.firstOtherButtonIndex + 1) {
		[[UIApplication sharedApplication] openURL:self.tracktivityURL];
	}
	self.actionSheet = nil;
}

#pragma mark UIViewController Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	if (self.wrappedTrack == nil) {
		self.navigationItem.rightBarButtonItem = nil;
	}
}

- (void)viewDidUnload
{
	[self setActionButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
