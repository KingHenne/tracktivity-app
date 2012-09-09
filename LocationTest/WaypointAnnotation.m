//
//  WaypointAnnotation.m
//  LocationTest
//
//  Created by Hendrik Liebau on 15.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "WaypointAnnotation.h"

@interface WaypointAnnotation ()
@property (nonatomic, strong) NSDate *timestamp;
@end

@implementation WaypointAnnotation

@synthesize index = _index;
@synthesize timestamp = _timestamp;
@synthesize coordinate = _coordinate;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coord
{
	self = [super init];
	if (self) {
		_coordinate = coord;
	}
	return self;
}

- (NSString *)title
{
	if (self.index == kWaypointAnnotationStart) {
		return NSLocalizedString(@"StartWaypoint", @"Waypoint marking the start of the track");
	} else if (self.index == kWaypointAnnotationEnd) {
		return NSLocalizedString(@"EndWaypoint", @"Waypoint marking the end of the track");
	}
	return [NSString stringWithFormat:NSLocalizedString(@"WaypointTitleFormat", @"Waypoint title format with index number"), self.index];
}

- (NSString *)subtitle
{
	return [NSDateFormatter localizedStringFromDate:self.timestamp
										  dateStyle:NSDateFormatterNoStyle
										  timeStyle:NSDateFormatterLongStyle];
}

+ (WaypointAnnotation *)annotationForWaypoint:(Waypoint *)waypoint withIndexNumber:(int)index
{
	CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(waypoint.latitude.doubleValue, waypoint.longitude.doubleValue);
	WaypointAnnotation *annotation = [[WaypointAnnotation alloc] initWithCoordinate:coord];
	annotation.timestamp = waypoint.time;
	annotation.index = index;
	return annotation;
}

+ (WaypointAnnotation *)annotationForLocation:(CLLocation *)location withIndexNumber:(int)index
{
	WaypointAnnotation *annotation = [[WaypointAnnotation alloc] initWithCoordinate:location.coordinate];
	annotation.timestamp = location.timestamp;
	annotation.index = index;
	return annotation;
}

+ (WaypointAnnotation *)annotationForStartWaypoint:(Waypoint *)waypoint
{
	return [WaypointAnnotation annotationForWaypoint:waypoint withIndexNumber:kWaypointAnnotationStart];
}

+ (WaypointAnnotation *)annotationForStartLocation:(CLLocation *)location
{
	return [WaypointAnnotation annotationForLocation:location withIndexNumber:kWaypointAnnotationStart];
}

+ (WaypointAnnotation *)annotationForEndWaypoint:(Waypoint *)waypoint
{
	return [WaypointAnnotation annotationForWaypoint:waypoint withIndexNumber:kWaypointAnnotationEnd];
}

+ (WaypointAnnotation *)annotationForEndLocation:(CLLocation *)location
{
	return [WaypointAnnotation annotationForLocation:location withIndexNumber:kWaypointAnnotationEnd];
}

@end
