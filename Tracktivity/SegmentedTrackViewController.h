//
//  SegmentedControlViewController.h
//  Tracktivity
//
//  Created by Hendrik on 05.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RestKit/RestKit.h>
#import "TrackTableViewController.h"

@interface SegmentedTrackViewController : UIViewController

enum {
	kActivityViewController = 0,
	kRouteViewController = 1
};

- (void)setCurrentViewControllerWithIndex:(NSUInteger)viewControllerIndex;
- (TrackTableViewController *)currentViewController;

@end
