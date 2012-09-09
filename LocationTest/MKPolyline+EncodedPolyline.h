//
//  MKPolyline+EncodedPolyline.h
//  LocationTest
//
//  Created by Hendrik on 29.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MKPolyline (EncodedPolyline)

+ (MKPolyline *)polylineWithEncodedString:(NSString *)encodedString;

@end
