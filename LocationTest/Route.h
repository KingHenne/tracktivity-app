//
//  Route.h
//  LocationTest
//
//  Created by Hendrik on 30.09.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Track.h"


@interface Route : Track

@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSData * originalFile;

@end
