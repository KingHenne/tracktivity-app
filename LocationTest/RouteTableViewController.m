//
//  RouteTableViewController.m
//  LocationTest
//
//  Created by Hendrik on 05.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "RouteTableViewController.h"
#import "Route.h"
#import <RestKit/RestKit.h>

@implementation RouteTableViewController

- (void)setupFetchedResultsController
{
	self.debug = YES;
	self.fetchedResultsController = [Route fetchAllSortedBy:@"created" ascending:NO withPredicate:nil groupBy:nil];
}

@end
