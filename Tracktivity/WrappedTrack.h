//
//  WrappedTrack.h
//  Tracktivity
//
//  Created by Hendrik on 03.10.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Track;

@interface WrappedTrack : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * updated;
@property (nonatomic, retain) Track *track;

@end
