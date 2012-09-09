//
//  Segment+Create.m
//  LocationTest
//
//  Created by Hendrik Liebau on 22.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "Segment+Create.h"
#import "Waypoint+Create.h"
#import <CoreLocation/CoreLocation.h>

@implementation Segment (Create)

+ (Segment *)segmentWithLocations:(NSArray *)locations
		   inManagedObjectContext:(NSManagedObjectContext *)context
{
	Segment *segment = [NSEntityDescription insertNewObjectForEntityForName:@"Segment" inManagedObjectContext:context];
	for (CLLocation *location in locations) {
		[segment addPointsObject:[Waypoint waypointWithLocation:location inManagedObjectContext:context]];
	}
	return segment;
}

- (void)addPointsObject:(Waypoint *)value
{
	NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.points];
	[tempSet addObject:value];
	self.points = tempSet;
}

@end
