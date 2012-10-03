//
//  Route.h
//  LocationTest
//
//  Created by Hendrik on 03.10.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "WrappedTrack.h"


@interface Route : WrappedTrack

@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSData * originalFile;

@end
