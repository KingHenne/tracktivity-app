//
//  WrappedTrack+Info.m
//  LocationTest
//
//  Created by Hendrik on 04.10.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "WrappedTrack+Info.h"
#import "Activity.h"
#import "Route.h"

@implementation WrappedTrack (Info)

- (NSString *)title
{
	if (self.name) return self.name;
	if ([self isKindOfClass:[Activity class]]) {
		Activity *activity = (Activity *) self;
		return [NSDateFormatter localizedStringFromDate:activity.start dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
	}
	return @"";
}

- (NSString *)subTitle
{
	if ([self isKindOfClass:[Activity class]]) {
		Activity *activity = (Activity *) self;
		if (self.name) {
			return [NSDateFormatter localizedStringFromDate:activity.start dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
		} else {
			return [NSDateFormatter localizedStringFromDate:activity.end dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
		}
		
	} else if ([self isKindOfClass:[Route class]]) {
		Route *route = (Route *) self;
		return [NSDateFormatter localizedStringFromDate:route.created dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
	}
	return @"";
}

@end
