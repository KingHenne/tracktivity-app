//
//  WaypointAnnotation.h
//  Tracktivity
//
//  Created by Hendrik Liebau on 15.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MKAnnotation.h>
#import "Waypoint.h"

@interface WaypointAnnotation : NSObject <MKAnnotation>

enum {
	kWaypointAnnotationStart = 0,
	kWaypointAnnotationEnd = -1
};

@property (nonatomic) int index;

// designated initalizer
- (id)initWithCoordinate:(CLLocationCoordinate2D)coord;
+ (WaypointAnnotation *)annotationForStartWaypoint:(Waypoint *)waypoint;
+ (WaypointAnnotation *)annotationForStartLocation:(CLLocation *)location;
+ (WaypointAnnotation *)annotationForEndWaypoint:(Waypoint *)waypoint;
+ (WaypointAnnotation *)annotationForEndLocation:(CLLocation *)location;
+ (WaypointAnnotation *)annotationForWaypoint:(Waypoint *)waypoint
							  withIndexNumber:(int)index;
+ (WaypointAnnotation *)annotationForLocation:(CLLocation *)location
							  withIndexNumber:(int)index;

@end
