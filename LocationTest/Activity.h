//
//  Activity.h
//  LocationTest
//
//  Created by Hendrik on 03.10.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NamedTrack.h"


@interface Activity : NamedTrack

@property (nonatomic, retain) NSDate * end;
@property (nonatomic, retain) NSNumber * recording;
@property (nonatomic, retain) NSDate * start;
@property (nonatomic, retain) NSString * tracktivityID;
@property (nonatomic, retain) NSString * type;

@end
