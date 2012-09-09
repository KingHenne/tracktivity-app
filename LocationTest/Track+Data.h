//
//  Track+Data.h
//  LocationTest
//
//  Created by Hendrik Liebau on 23.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "Track.h"
#import <MapKit/MKMapView.h>
#import "Waypoint.h"

@interface Track (Data)

- (MKPolyline *)polyline;
- (NSString *)encodedPolylineString;
- (NSString *)pathPointsString;
- (Waypoint *)firstPoint;
- (Waypoint *)lastPoint;

@end
