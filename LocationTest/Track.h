//
//  Track.h
//  LocationTest
//
//  Created by Hendrik on 03.10.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Segment, Waypoint, WrappedTrack;

@interface Track : NSManagedObject

@property (nonatomic, retain) id thumbnail;
@property (nonatomic, retain) NSOrderedSet *segments;
@property (nonatomic, retain) WrappedTrack *parent;
@property (nonatomic, retain) NSOrderedSet *waypoints;
@end

@interface Track (CoreDataGeneratedAccessors)

- (void)insertObject:(Segment *)value inSegmentsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromSegmentsAtIndex:(NSUInteger)idx;
- (void)insertSegments:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeSegmentsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInSegmentsAtIndex:(NSUInteger)idx withObject:(Segment *)value;
- (void)replaceSegmentsAtIndexes:(NSIndexSet *)indexes withSegments:(NSArray *)values;
- (void)addSegmentsObject:(Segment *)value;
- (void)removeSegmentsObject:(Segment *)value;
- (void)addSegments:(NSOrderedSet *)values;
- (void)removeSegments:(NSOrderedSet *)values;
- (void)insertObject:(Waypoint *)value inWaypointsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromWaypointsAtIndex:(NSUInteger)idx;
- (void)insertWaypoints:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeWaypointsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInWaypointsAtIndex:(NSUInteger)idx withObject:(Waypoint *)value;
- (void)replaceWaypointsAtIndexes:(NSIndexSet *)indexes withWaypoints:(NSArray *)values;
- (void)addWaypointsObject:(Waypoint *)value;
- (void)removeWaypointsObject:(Waypoint *)value;
- (void)addWaypoints:(NSOrderedSet *)values;
- (void)removeWaypoints:(NSOrderedSet *)values;
@end
