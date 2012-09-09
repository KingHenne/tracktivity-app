//
//  SegmentedControlViewController.h
//  LocationTest
//
//  Created by Hendrik on 05.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SegmentedControlViewController : UIViewController

enum {
	kActivityViewController = 0,
	kRouteViewController = 1
};

- (void)setCurrentViewControllerWithIndex:(int)viewControllerIndex;
- (UITableViewController *)currentTableViewController;

@end
