//
//  ActivityType.m
//  Tracktivity
//
//  Created by Hendrik on 07.10.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "ActivityType.h"
#import "Activity.h"


@implementation ActivityType

@dynamic stringValue;
@dynamic emojiIcon;
@dynamic displayOrder;
@dynamic localizedLabel;
@dynamic activities;

- (NSString *)localizedLabel
{
	NSString *key = [NSString stringWithFormat:@"activity.%@", self.stringValue];
	return [[NSBundle mainBundle] localizedStringForKey:(key) value:@"" table:nil];
}

@end
