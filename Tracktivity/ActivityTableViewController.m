//
//  ActivityTableViewController.m
//  Tracktivity
//
//  Created by Hendrik on 05.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "ActivityTableViewController.h"
#import "Activity.h"
#import <RestKit/RestKit.h>

@interface ActivityTableViewController () <RKObjectLoaderDelegate, RKRequestDelegate>
@property (nonatomic, strong) UIBarButtonItem *refreshButton;
@end

@implementation ActivityTableViewController

@synthesize refreshButton = _refreshButton;

- (void)setupFetchedResultsController
{
	self.debug = YES;
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"recording == 0"];
	self.fetchedResultsController = [Activity fetchAllSortedBy:@"start" ascending:NO withPredicate:predicate groupBy:nil];
}

- (IBAction)refreshButtonPressed:(UIBarButtonItem *)sender
{
	self.refreshButton = sender;
	self.refreshButton.enabled = NO;
	[self uploadNewActivities];
	[self fetchActivityList];
}

- (void)uploadNewActivities
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(tracktivityID == nil) AND (recording == 0)"];
	NSArray *newActivities = [Activity findAllWithPredicate:predicate];
	for (Activity *newActivity in newActivities) {
		[[RKObjectManager sharedManager] postObject:newActivity delegate:self];
	}
}

- (void)fetchActivityList
{
	[[[RKObjectManager sharedManager] client] get:@"/users/hendrik/activities" delegate:self];
}

// activityIDs must be an array of dictionaries with a key 'id'
- (void)downloadNewActivities:(NSArray *)activityIDs
{
	for (NSDictionary *activity in activityIDs) {
		NSString *tracktivityID = [activity valueForKey:@"id"];
		if (tracktivityID && [Activity findByPrimaryKey:tracktivityID] == nil) {
			NSLog(@"Loading activity %@ from the server...", tracktivityID);
			NSString *path = [NSString stringWithFormat:@"/activities/%@", tracktivityID];
			[RKObjectManager.sharedManager loadObjectsAtResourcePath:path delegate:self];
		}
	}
}

- (void)deleteActivitiesNotIncludedInList:(NSArray *)activityIDs
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"tracktivityID != nil"];
	NSArray *activities = [Activity findAllWithPredicate:predicate];
	for (Activity *activity in activities) {
		NSDictionary *testDict = [NSDictionary dictionaryWithObject:activity.tracktivityID forKey:@"id"];
		if (![activityIDs containsObject:testDict]) {
			NSLog(@"Deleting activity %@ now.", activity.tracktivityID);
			[activity deleteEntity];
			[self saveContext];
		}
	}
}

- (void)saveContext
{
	NSError *error;
	if (![RKManagedObjectStore.defaultObjectStore save:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
}

#pragma mark RestKit Delegate Methods

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response
{
	if (request.method == RKRequestMethodGET && response.isJSON) {
		NSError * error;
		NSDictionary *responseBody = [response parsedBody:&error];
		if (responseBody) {
			NSArray *activityIDs = [responseBody valueForKey:@"activities"];
			if (activityIDs) {
				[self downloadNewActivities:activityIDs];
				[self deleteActivitiesNotIncludedInList:activityIDs];
			}
		} else {
			NSLog(@"Error parsing response: %@, %@", error, [error userInfo]);
		}
	}
	if (RKObjectManager.sharedManager.requestQueue.count <= 1) {
		self.refreshButton.enabled = YES;
	}
}

- (void)objectLoaderDidFinishLoading:(RKObjectLoader *)objectLoader
{
	if (RKObjectManager.sharedManager.requestQueue.count <= 1) {
		self.refreshButton.enabled = YES;
	}
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error
{
	NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error
{
	NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	NSString *localizedErrorMessage = [error.userInfo objectForKey:@"NSLocalizedDescription"];
	NSString *cancelButtonTitle = NSLocalizedString(@"AlertViewOK", @"alert view ok button label");
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:localizedErrorMessage delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles: nil];
	[alertView show];
	self.refreshButton.enabled = YES;
}

- (void)requestDidTimeout:(RKRequest *)request
{
	self.refreshButton.enabled = YES;
}

@end
