//
//  TrackHandler.h
//  Tracktivity
//
//  Created by Hendrik Liebau on 23.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WrappedTrack.h"

@protocol WrappedTrackHandler <NSObject>

@property (nonatomic, strong) WrappedTrack *wrappedTrack;

@end
