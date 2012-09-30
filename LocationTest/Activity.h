//
//  Activity.h
//  LocationTest
//
//  Created by Hendrik on 30.09.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Track.h"


@interface Activity : Track

@property (nonatomic, retain) NSDate * end;
@property (nonatomic, retain) NSDate * start;
@property (nonatomic, retain) NSString * tracktivityID;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * recording;

@end
