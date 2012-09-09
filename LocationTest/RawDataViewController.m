//
//  SecondViewController.m
//  LocationTest
//
//  Created by Hendrik Liebau on 14.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "RawDataViewController.h"
#import "TrackingManager.h"
#import "CLLocation+Strings.h"
#import "NSDate+Strings.h"

@interface RawDataViewController () <TrackingManagerDelegate>
@property (nonatomic, strong, readonly) TrackingManager *trackingManager;
@property (nonatomic, strong) NSTimer *updateTimer;
// Outlets
@property (weak, nonatomic) IBOutlet UILabel *latitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *longitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *altitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *horizontalAccuracyLabel;
@property (weak, nonatomic) IBOutlet UILabel *verticalAccuracyLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentSpeedLabel;
@property (weak, nonatomic) IBOutlet UILabel *averageSpeedLabel;
@property (weak, nonatomic) IBOutlet UILabel *elapsedTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalDistanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *heartRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *cadenceLabel;
@property (weak, nonatomic) IBOutlet UILabel *wheelRotationLabel;
@end

@implementation RawDataViewController

@synthesize trackingManager = _trackingManager;
@synthesize updateTimer = _updateTimer;
@synthesize latitudeLabel = _latitudeLabel;
@synthesize longitudeLabel = _longitudeLabel;
@synthesize altitudeLabel = _altitudeLabel;
@synthesize horizontalAccuracyLabel = _horizontalAccuracyLabel;
@synthesize verticalAccuracyLabel = _verticalAccuracyLabel;
@synthesize currentSpeedLabel = _currentSpeedLabel;
@synthesize averageSpeedLabel = _averageSpeedLabel;
@synthesize elapsedTimeLabel = _elapsedTimeLabel;
@synthesize totalDistanceLabel = _totalDistanceLabel;
@synthesize heartRateLabel = _heartRateLabel;
@synthesize cadenceLabel = _cadenceLabel;
@synthesize wheelRotationLabel = _wheelRotationLabel;

- (TrackingManager *)trackingManager
{
	if (_trackingManager == nil) {
		_trackingManager = [TrackingManager sharedTrackingManager];
		_trackingManager.delegate = self;
	}
	return _trackingManager;
}

- (NSTimer *)updateTimer
{
	if (_updateTimer == nil) { // lazy instantiation
		
	}
	return _updateTimer;
}

- (void)resetLabels
{
	self.latitudeLabel.text = @"—";
	self.longitudeLabel.text = @"—";
	self.altitudeLabel.text = @"—";
	self.horizontalAccuracyLabel.text = @"—";
	self.verticalAccuracyLabel.text = @"—";
	self.currentSpeedLabel.text = @"—";
	self.averageSpeedLabel.text = @"—";
	self.elapsedTimeLabel.text = @"—";
	self.totalDistanceLabel.text = @"—";
	self.heartRateLabel.text = @"—";
	self.cadenceLabel.text = @"—";
	self.wheelRotationLabel.text = @"—";
}

- (void)updateTimeRelatedViews
{
	self.elapsedTimeLabel.text = [self.trackingManager.startTime formattedTimeIntervalSinceNow];
	double totalTimeInSeconds = abs([self.trackingManager.startTime timeIntervalSinceNow]);
	CLLocationDistance totalDistanceInKm = self.trackingManager.totalDistance / 1000.0;
	double averageSpeedInKph = totalDistanceInKm / totalTimeInSeconds * 3600;
	self.averageSpeedLabel.text = [NSString stringWithFormat:NSLocalizedString(@"SpeedFormat", @"SpeedFormat"), averageSpeedInKph];
}

- (void)startUpdateTimer
{
	self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
														target:self
													  selector:@selector(updateTimeRelatedViews)
													  userInfo:nil
													   repeats:YES];
}

- (void)updateViewsWithLocation:(CLLocation *)location
{
	if (location == nil) return;
	self.latitudeLabel.text = location.localizedLatitudeString;
	self.longitudeLabel.text = location.localizedLongitudeString;
	self.altitudeLabel.text = location.localizedAltitudeString;
	self.horizontalAccuracyLabel.text = location.localizedHorizontalAccuracyString;
	self.verticalAccuracyLabel.text = location.localizedVerticalAccuracyString;
	self.currentSpeedLabel.text = location.localizedSpeedString;
	CLLocationDistance totalDistanceInKm = self.trackingManager.totalDistance / 1000.0;
	self.totalDistanceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"DistanceFormat", @"Distance in km"), totalDistanceInKm];
}

#pragma mark TrackingManagerDelegate Methods

- (void)locationUpdate:(CLLocation *)location
{
	[self updateViewsWithLocation:location];
}

#pragma mark UIViewController Methods

- (void)viewWillAppear:(BOOL)animated
{
	self.trackingManager.delegate = self;
	if (self.trackingManager.recording) {
		[self startUpdateTimer];
	}
	[self updateViewsWithLocation:self.trackingManager.location];
	[self updateTimeRelatedViews];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[self.updateTimer invalidate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self resetLabels];
}

- (void)viewDidUnload
{
	[self setLatitudeLabel:nil];
	[self setLongitudeLabel:nil];
	[self setAltitudeLabel:nil];
	[self setHorizontalAccuracyLabel:nil];
	[self setVerticalAccuracyLabel:nil];
	[self setCurrentSpeedLabel:nil];
	[self setAverageSpeedLabel:nil];
	[self setElapsedTimeLabel:nil];
	[self setTotalDistanceLabel:nil];
	[self setHeartRateLabel:nil];
	[self setCadenceLabel:nil];
	[self setWheelRotationLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	} else {
	    return YES;
	}
}

#pragma mark LocationControllerDelegate Methods

- (void)toggledRecording:(BOOL)recording
{
	if (recording) {
		[self startUpdateTimer];
	} else {
		[self.updateTimer invalidate];
	}
}

@end
