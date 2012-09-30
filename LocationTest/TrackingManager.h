//
//  LocationController.h
//  LocationTest
//
//  Created by Hendrik Liebau on 15.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MKMapView.h>
#import "Activity.h"

@protocol TrackingManagerDelegate <NSObject>
@optional
- (void)locationUpdate:(CLLocation *)location;
- (void)startedActivity;
- (void)finishedActivity;
- (void)toggledPause:(BOOL)paused;
- (void)locationUpdateFailedWithError:(NSError *)error;
@end

@interface TrackingManager : NSObject <CLLocationManagerDelegate>

@property (nonatomic, weak) id <TrackingManagerDelegate> delegate;
@property (nonatomic, assign, getter = isPaused) BOOL paused;

- (BOOL)isRecordingActivity;
- (void)togglePause;
- (void)startActivity;
- (void)finishActivity;
- (CLLocation *)location;
- (CLLocationDistance)totalDistance;
- (Activity *)activity;
- (void)startUpdatingWithoutRecording;
- (void)stopUpdatingWithoutRecording;

+ (TrackingManager *)sharedTrackingManager;

@end
