//
//  Waypoint+Create.m
//  LocationTest
//
//  Created by Hendrik Liebau on 22.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "Waypoint+Create.h"

@implementation Waypoint (Create)

+ (Waypoint *)waypointWithLocation:(CLLocation *)location
			inManagedObjectContext:(NSManagedObjectContext *)context
{
	Waypoint *point = [NSEntityDescription insertNewObjectForEntityForName:@"Waypoint"
													inManagedObjectContext:context];
	point.latitude = [NSNumber numberWithDouble:location.coordinate.latitude];
	point.longitude = [NSNumber numberWithDouble:location.coordinate.longitude];
	point.time = location.timestamp;
	point.elevation = [NSNumber numberWithDouble:location.altitude];
	return point;
}

@end
