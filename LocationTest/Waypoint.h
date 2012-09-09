//
//  Waypoint.h
//  LocationTest
//
//  Created by Hendrik on 04.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Segment;

@interface Waypoint : NSManagedObject

@property (nonatomic, retain) NSNumber * cadence;
@property (nonatomic, retain) NSNumber * elevation;
@property (nonatomic, retain) NSNumber * heartrate;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) Segment *segment;

@end
