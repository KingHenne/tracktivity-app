//
//  Waypoint+Strings.m
//  Tracktivity
//
//  Created by Hendrik on 29.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "Waypoint+Strings.h"

@implementation Waypoint (Strings)

- (NSString *)description
{
	return [NSString stringWithFormat:@"%f,%f", self.latitude.doubleValue, self.longitude.doubleValue];
}

@end
