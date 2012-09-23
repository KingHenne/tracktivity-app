//
//  ActivityTableViewController.m
//  LocationTest
//
//  Created by Hendrik on 05.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "ActivityTableViewController.h"
#import "Activity.h"
#import <RestKit/RestKit.h>

@implementation ActivityTableViewController

- (void)setupFetchedResultsController
{
	self.debug = YES;
	self.fetchedResultsController = [Activity fetchAllSortedBy:@"start" ascending:NO withPredicate:nil groupBy:nil];
}

@end
