//
//  NamedTrack.h
//  LocationTest
//
//  Created by Hendrik on 03.10.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Track;

@interface NamedTrack : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) Track *track;

@end
