//
//  Segment+Data.h
//  Tracktivity
//
//  Created by Hendrik on 23.09.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "Segment.h"
#import <MapKit/MKPolyline.h>

@interface Segment (Data)

- (MKPolyline *)polyline;
- (NSString *)encodedPolylineStringWithMinimumDistanceBetweenPoints:(float)minDist;

@end
