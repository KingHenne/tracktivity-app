//
//  Activity.h
//  Tracktivity
//
//  Created by Hendrik on 07.10.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "WrappedTrack.h"

@class ActivityType;

@interface Activity : WrappedTrack

@property (nonatomic, retain) NSDate * end;
@property (nonatomic, retain) NSNumber * recording;
@property (nonatomic, retain) NSDate * start;
@property (nonatomic, retain) NSString * tracktivityID;
@property (nonatomic, retain) ActivityType *type;

@end
