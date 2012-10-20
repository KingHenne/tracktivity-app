//
//  FirstViewController.h
//  Tracktivity
//
//  Created by Hendrik Liebau on 14.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "MapViewController.h"
#import "TrackingManager.h"
#import "FinishActivityViewController.h"

@interface RecordViewController : MapViewController <TrackingManagerDelegate, FinishActivityViewControllerPresenter>

@end
