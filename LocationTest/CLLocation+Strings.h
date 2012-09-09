//
//  CLLocation+Strings.h
//  LocationTest
//
//  Created by Hendrik Liebau on 15.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface CLLocation (Strings)

- (NSString *)localizedLatitudeString;
- (NSString *)localizedLongitudeString;
- (NSString *)localizedAltitudeString;
- (NSString *)localizedHorizontalAccuracyString;
- (NSString *)localizedVerticalAccuracyString;
- (NSString *)localizedCourseString;
- (NSString *)localizedSpeedString;

@end
