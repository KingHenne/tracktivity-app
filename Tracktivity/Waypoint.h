//
//  Waypoint.h
//  Tracktivity
//
//  Created by Hendrik on 03.10.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Segment, Track;

@interface Waypoint : NSManagedObject

@property (nonatomic, retain) NSNumber * cadence;
@property (nonatomic, retain) NSNumber * elevation;
@property (nonatomic, retain) NSNumber * heartrate;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) Segment *pointInSegment;
@property (nonatomic, retain) Track *waypointInTrack;

@end
