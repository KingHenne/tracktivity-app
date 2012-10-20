//
//  Activity+Create.h
//  Tracktivity
//
//  Created by Hendrik on 04.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "Activity.h"

@interface Activity (Create)

+ (Activity *)activityWithStart:(NSDate *)startDate
						 end:(NSDate *)endDate
	  inManagedObjectContext:(NSManagedObjectContext *)context;

@end
