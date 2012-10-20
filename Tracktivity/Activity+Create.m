//
//  Activity+Create.m
//  Tracktivity
//
//  Created by Hendrik on 04.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "Activity+Create.h"

@implementation Activity (Create)

+ (Activity *)activityWithStart:(NSDate *)startDate
						 end:(NSDate *)endDate
	  inManagedObjectContext:(NSManagedObjectContext *)context
{
	Activity *activity = [NSEntityDescription insertNewObjectForEntityForName:@"Activity" inManagedObjectContext:context];
	activity.start = startDate;
	activity.end = endDate;
	return activity;
}

@end
