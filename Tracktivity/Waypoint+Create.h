//
//  Waypoint+Create.h
//  Tracktivity
//
//  Created by Hendrik Liebau on 22.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "Waypoint.h"
#import <CoreLocation/CoreLocation.h>

@interface Waypoint (Create)

+ (Waypoint *)waypointWithLocation:(CLLocation *)location
			inManagedObjectContext:(NSManagedObjectContext *)context;

@end
