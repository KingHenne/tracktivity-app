//
//  Track+Create.m
//  Tracktivity
//
//  Created by Hendrik Liebau on 23.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "Track+Create.h"

@implementation Track (Create)

- (void)addSegmentsObject:(Segment *)value
{
	NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.segments];
	[tempSet addObject:value];
	self.segments = tempSet;
}

@end
