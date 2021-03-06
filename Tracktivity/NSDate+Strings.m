//
//  NSDate+Strings.m
//  Tracktivity
//
//  Created by Hendrik Liebau on 15.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "NSDate+Strings.h"

@implementation NSDate (Strings)

- (NSString *)formattedTimeIntervalSinceNow
{
	NSTimeInterval elapsedSeconds = abs([self timeIntervalSinceNow]);
	NSUInteger h = elapsedSeconds / 3600;
	NSUInteger m = ((NSUInteger)elapsedSeconds / 60) % 60;
	NSUInteger s = ((NSUInteger)elapsedSeconds) % 60;
	return [NSString stringWithFormat:@"%lu:%02lu:%02lu", (unsigned long)h, (unsigned long)m, (unsigned long)s];
}

@end
