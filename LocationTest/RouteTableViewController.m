//
//  RouteTableViewController.m
//  LocationTest
//
//  Created by Hendrik on 05.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "RouteTableViewController.h"
#import "AppDelegate.h"

@implementation RouteTableViewController

- (void)setupFetchedResultsController
{
	self.debug = YES;
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Route"];
	request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"created" ascending:NO]];
	
	AppDelegate * appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
	NSManagedObjectContext *context = appDelegate.managedObjectContext;
	
	self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:NULL cacheName:nil];
}

@end
