//
//  ActivityTableViewController.h
//  Tracktivity
//
//  Created by Hendrik Liebau on 23.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataTableViewController.h"
#import <RestKit/RestKit.h>

@interface TrackTableViewController : CoreDataTableViewController <UISplitViewControllerDelegate>

- (IBAction)trashButtonPressed:(UIBarButtonItem *)sender;

@end
