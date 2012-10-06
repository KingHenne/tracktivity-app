//
//  Activity+Type.m
//  LocationTest
//
//  Created by Hendrik on 06.10.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "Activity+Type.h"
#import "ActivityType.h"

@implementation Activity (Type)

- (NSString *)typeString
{
	return [ActivityType stringValueForActivity:self.type.intValue];
}

- (void)setTypeString:(NSString *)typeString
{
	self.type = [NSNumber numberWithInt:[ActivityType codeForStringValue:typeString]];
}

@end
