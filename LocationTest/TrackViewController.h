//
//  ActivityViewController.h
//  LocationTest
//
//  Created by Hendrik Liebau on 23.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "MapViewController.h"
#import "WrappedTrackHandler.h"
#import "SplitViewDetailController.h"

@interface TrackViewController : MapViewController <WrappedTrackHandler, SplitViewDetailController>

@end
