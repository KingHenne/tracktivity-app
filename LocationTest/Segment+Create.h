//
//  Segment+Create.h
//  LocationTest
//
//  Created by Hendrik Liebau on 22.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "Segment.h"

@interface Segment (Create)

+ (Segment *)segmentWithLocations:(NSArray *)locations
		   inManagedObjectContext:(NSManagedObjectContext *)context;

@end
