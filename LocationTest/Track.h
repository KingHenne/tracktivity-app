//
//  Track.h
//  LocationTest
//
//  Created by Hendrik on 03.10.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NamedTrack, Segment, Waypoint;

@interface Track : NSManagedObject

@property (nonatomic, retain) id thumbnail;
@property (nonatomic, retain) NSOrderedSet *segments;
@property (nonatomic, retain) NamedTrack *parent;
@property (nonatomic, retain) NSSet *waypoints;
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
- (void)addWaypointsObject:(Waypoint *)value;
- (void)removeWaypointsObject:(Waypoint *)value;
- (void)addWaypoints:(NSSet *)values;
- (void)removeWaypoints:(NSSet *)values;

@end
