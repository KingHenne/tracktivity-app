//
//  RouteTableViewController.m
//  Tracktivity
//
//  Created by Hendrik on 05.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "RouteTableViewController.h"
#import "Route.h"
#import <RestKit/RestKit.h>

@interface RouteTableViewController ()
@property (nonatomic, strong) WrappedTrack *importedRoute;
@end

@implementation RouteTableViewController

@synthesize importedRoute = _importedRoute;

- (void)setupFetchedResultsController
{
	self.debug = YES;
	NSManagedObjectContext *context = [[RKManagedObjectStore defaultStore] mainQueueManagedObjectContext];
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Route"];
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"created" ascending:NO];
	[fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:@"allRoutes"];
}

- (void)displayImportedRoute
{
	if (self.importedRoute == nil) return;
	NSUInteger index = [self.fetchedResultsController.fetchedObjects indexOfObject:self.importedRoute];
	if (index != NSNotFound) {
		NSIndexPath *cellIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
		[self performSegueWithIdentifier:@"Show Route Details"
								  sender:[self.tableView cellForRowAtIndexPath:cellIndexPath]];
	}
	self.importedRoute = nil;
}

- (void)displayImportedTrackNotification:(NSNotification *)notification
{
	self.importedRoute = notification.object;
	if (self.view.window) {
		[self displayImportedRoute];
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self name:DisplayImportedTrackNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	if (self.importedRoute) {
		[self displayImportedRoute];
	}
}

@end
