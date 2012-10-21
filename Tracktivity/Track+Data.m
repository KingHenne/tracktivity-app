//
//  Track+Data.m
//  Tracktivity
//
//  Created by Hendrik Liebau on 23.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "Track+Data.h"
#import "Segment+Data.h"
#import "Waypoint.h"

#define VERYSMALL 0.0001

@implementation Track (Data)

- (int)numberOfTotalPoints
{
	int count = 0;
	for (Segment *segment in self.segments) {
		count += segment.points.count;
	}
	return count;
}

- (Waypoint *)firstPoint
{
	Segment *firstSegment = self.segments.firstObject;
	return firstSegment.points.firstObject;
}

- (Waypoint *)lastPoint
{
	Segment *lastSegment = self.segments.lastObject;
	return lastSegment.points.lastObject;
}

- (MultiPolyline *)multiPolyline
{
	MultiPolyline *multiPolyline = [MultiPolyline new];
	for (Segment *segment in self.segments) {
		MKPolyline *segmentPolyline = segment.polyline;
		if (segmentPolyline) {
			[multiPolyline addPolyline:segmentPolyline];
		}
	}
	return multiPolyline;
}

- (NSArray *)encodedPolylineStrings
{
	NSMutableArray *encodedPolylineStrings = [NSMutableArray new];
	int count = self.numberOfTotalPoints;
	float minDist = VERYSMALL * pow(count, 4) / 2.8e12;
	for (Segment *segment in self.segments) {
		[encodedPolylineStrings addObject:[segment encodedPolylineStringWithMinimumDistanceBetweenPoints:minDist]];
	}
	return encodedPolylineStrings;
}

@end
