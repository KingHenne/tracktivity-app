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
#import "MultiPolyline.h"

@interface Track (Data)

- (MultiPolyline *)multiPolyline;
- (NSArray *)encodedPolylineStrings;
- (Waypoint *)firstPoint;
- (Waypoint *)lastPoint;
- (int)numberOfTotalPoints;

@end
