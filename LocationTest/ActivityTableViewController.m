//
//  ActivityTableViewController.m
//  LocationTest
//
//  Created by Hendrik on 05.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "ActivityTableViewController.h"
#import "AppDelegate.h"

@implementation ActivityTableViewController

- (void)setupFetchedResultsController
{
	self.debug = YES;
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Activity"];
	request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"start" ascending:NO]];
	
	AppDelegate * appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
	NSManagedObjectContext *context = appDelegate.managedObjectContext;
	
	self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:NULL cacheName:nil];
}

@end
