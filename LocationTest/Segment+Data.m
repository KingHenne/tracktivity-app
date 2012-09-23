//
//  Segment+Data.m
//  LocationTest
//
//  Created by Hendrik on 23.09.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "Segment+Data.h"
#import "Waypoint.h"

@implementation Segment (Data)

- (MKPolyline *)polyline
{
	MKPolyline *polyline;
	NSOrderedSet *points = [self points];
	int numPoints = points.count;
	if (numPoints > 1)
	{
		CLLocationCoordinate2D* coords = malloc(numPoints * sizeof(CLLocationCoordinate2D));
		for (int i = 0; i < numPoints; i++)
		{
			Waypoint *point = [points objectAtIndex:i];
			coords[i] = CLLocationCoordinate2DMake(point.latitude.doubleValue, point.longitude.doubleValue);
		}
		polyline = [MKPolyline polylineWithCoordinates:coords count:numPoints];
		free(coords);
	}
	return polyline;
}

- (NSString *)encodeNumber:(int)num
{
	NSMutableString *encodeString = [NSMutableString string];
	int nextValue, finalValue;
	while (num >= 0x20) {
		nextValue = (0x20 | (num & 0x1f)) + 63;
		//     if (nextValue == 92) {
		//       [encodeString appendFormat:@"%c", (char)nextValue];
		//     }
		[encodeString appendFormat:@"%c", (char)nextValue];
		num >>= 5;
	}
	finalValue = num + 63;
	//   if (finalValue == 92) {
	//     [encodeString appendFormat:@"%c", (char)finalValue];
	//   }
	[encodeString appendFormat:@"%c", (char)finalValue];
	return encodeString;
}

- (NSString *)encodeSignedNumber:(int)num
{
	int sgn_num = num << 1;
	if (num < 0) {
		sgn_num = ~(sgn_num);
	}
	return [self encodeNumber:sgn_num];
}

// Computes the distance between the point p0 and the segment [p1,p2].
- (double)distanceBetweenPoint:(Waypoint *)p0 andSegmentWithPoint:(Waypoint *)p1 andPoint:(Waypoint *)p2
{
	double u, result = 0;
	double p0lat = p0.latitude.doubleValue;
	double p1lat = p1.latitude.doubleValue;
	double p2lat = p2.latitude.doubleValue;
	double p0lng = p0.longitude.doubleValue;
	double p1lng = p1.longitude.doubleValue;
	double p2lng = p2.longitude.doubleValue;
	
	double segmentLength = pow(p2lat - p1lat, 2) + pow(p2lng - p1lng, 2);
	
	if (p1lat == p2lat && p1lng == p2lng) {
		result = sqrt(pow(p2lat - p0lat, 2) + pow(p2lng - p0lng, 2));
	}
	else {
		u = ((p0lat - p1lat) * (p2lat - p1lat) + (p0lng - p1lng) * (p2lng - p1lng)) / segmentLength;
		
		if (u <= 0) {
			result = sqrt(pow(p0lat - p1lat, 2) + pow(p0lng - p1lng, 2));
		}
		if (u >= 1) {
			result = sqrt(pow(p0lat - p2lat, 2) + pow(p0lng - p2lng, 2));
		}
		if (0 < u && u < 1) {
			result = sqrt(pow(p0lat - p1lat - u*(p2lat - p1lat), 2) + pow(p0lng - p1lng - u*(p2lng - p1lng), 2));
		}
	}
	return result;
}

- (double *)computeDistancesForPoints:(NSArray *)points withMinimumDistanceBetweenPoints:(float)minDist
{
	int maxLoc = 0;
	double maxDist = 0;
	double absMaxDist = 0;
	
	NSMutableArray *stack = [NSMutableArray array];
	double *dists = calloc(points.count, sizeof(double));
	for (int i = 0; i < points.count; i++) {
		dists[i] = -1;
	}
	
	NSLog(@"computing distances for %d points using distance limit %.6f", points.count, minDist);
	if (points.count > 2) {
		[stack addObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:0], [NSNumber numberWithInt:points.count-1], nil]];
		while (stack.count > 0) {
			NSArray *current = stack.lastObject;
			[stack removeLastObject];
			maxDist = 0;
			int idx0 = ((NSNumber *)[current objectAtIndex:0]).integerValue;
			int idx1 = ((NSNumber *)[current objectAtIndex:1]).integerValue;
			Waypoint *p0 = [points objectAtIndex:idx0];
			Waypoint *p1 = [points objectAtIndex:idx1];
			for (int i = idx0 + 1; i < idx1; i++) {
				double temp = [self distanceBetweenPoint:[points objectAtIndex:i] andSegmentWithPoint:p0 andPoint:p1];
				if (temp > maxDist) {
					maxDist = temp;
					maxLoc = i;
					if (maxDist > absMaxDist) {
						absMaxDist = maxDist;
					}
				}
			}
			if (maxDist > minDist) {
				dists[maxLoc] = maxDist;
				[stack addObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:idx0], [NSNumber numberWithInt:maxLoc], nil]];
				[stack addObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:maxLoc], [NSNumber numberWithInt:idx1], nil]];
			}
		}
	}
	
	return dists;
}

- (NSString *)encodedPolylineStringWithMinimumDistanceBetweenPoints:(float)minDist
{
	int dlat, dlng;
	int plat = 0;
	int plng = 0;
	
	NSArray *points = self.points.array;
	NSMutableString *encodedPoints = [NSMutableString string];
	double *dists = [self computeDistancesForPoints:points withMinimumDistanceBetweenPoints:minDist];
	
	for (int i = 0; i < points.count; i++) {
		Waypoint *point = [points objectAtIndex:i];
		if (dists[i] != -1 || i == 0 || i == points.count-1) {
			int late5 = floor(point.latitude.doubleValue * 1e5);
			int lnge5 = floor(point.longitude.doubleValue * 1e5);
			dlat = late5 - plat;
			dlng = lnge5 - plng;
			plat = late5;
			plng = lnge5;
			[encodedPoints appendFormat:@"%@%@", [self encodeSignedNumber:dlat], [self encodeSignedNumber:dlng]];
		}
	}
	
	free(dists);
	return encodedPoints;
}

@end
