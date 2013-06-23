//
//  MultiPolyline.h
//  Tracktivity
//
//  Created by Hendrik on 23.09.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MKPolyline.h>

@interface MultiPolyline : NSObject

- (void)addPolyline:(MKPolyline *)polyline;
- (NSArray *)polylines;

@end
