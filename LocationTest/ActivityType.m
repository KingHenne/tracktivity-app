//
//  ActivityType.m
//  LocationTest
//
//  Created by Hendrik on 06.10.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "ActivityType.h"

@implementation ActivityType

+ (ActivityTypeCode)codeForStringValue:(NSString *)value
{
	if ([value isEqualToString:@"CYCLING"]) {
		return CYCLING;
	} else if ([value isEqualToString:@"HIKING"]) {
		return HIKING;
	} else if ([value isEqualToString:@"RUNNING"]) {
		return RUNNING;
	} else if ([value isEqualToString:@"INLINE"]) {
		return INLINE;
	}
	return -1;
}

+ (NSString *)stringValueForActivity:(ActivityTypeCode)code
{
	switch (code) {
		case CYCLING:
			return @"CYCLING";
		case HIKING:
			return @"HIKING";
		case RUNNING:
			return @"RUNNING";
		case INLINE:
			return @"INLINE";
	}
	return @"";
}

+ (NSDictionary *)localizedLabels
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			NSLocalizedString(@"activity.cycling", @"activity type cycling"), [NSNumber numberWithInt:CYCLING],
			NSLocalizedString(@"activity.running", @"activity type running"), [NSNumber numberWithInt:RUNNING],
			NSLocalizedString(@"activity.hiking", @"activity type hiking"), [NSNumber numberWithInt:HIKING],
			NSLocalizedString(@"activity.inline", @"activity type inline skating"), [NSNumber numberWithInt:INLINE], nil];
}

+ (NSString *)localizedLabelForActivity:(ActivityTypeCode)code
{
	return [[self.class localizedLabels] objectForKey:[NSNumber numberWithInt:code]];
}

+ (NSString *)emojiIconForActivity:(ActivityTypeCode)code
{
	switch (code) {
		case CYCLING:
			return @"🚴";
		case HIKING:
			return @"🚶";
		case RUNNING:
			return @"🏃";
		case INLINE:
			return @"🏃";
	}
	return nil;
}

@end
