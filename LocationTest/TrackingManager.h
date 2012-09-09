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

@protocol TrackingManagerDelegate <NSObject>
@optional
- (void)locationUpdate:(CLLocation *)location;
- (void)toggledRecording:(BOOL)recording;
- (void)locationUpdateFailedWithError:(NSError *)error;
@end

@interface TrackingManager : NSObject <CLLocationManagerDelegate>

@property (nonatomic, weak) id <TrackingManagerDelegate> delegate;
@property (nonatomic, assign) BOOL recording;

- (void)toggleRecording;
- (void)startUpdatingWithoutRecording;
- (void)stopUpdatingWithoutRecording;
- (CLLocation *)location;
- (CLLocationDistance)totalDistance;
- (NSDate *)startTime;
- (NSDate *)stopTime;
- (MKPolyline *)polyline;

+ (TrackingManager *)sharedTrackingManager;

@end
