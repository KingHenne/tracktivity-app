//
//  ActivityTableViewController.m
//  Tracktivity
//
//  Created by Hendrik on 05.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "ActivityTableViewController.h"
#import "Activity.h"
#import "ThinActivity.h"
#import <RestKit/RestKit.h>

@interface ActivityTableViewController ()

@end

@implementation ActivityTableViewController

- (void)setupFetchedResultsController
{
	self.debug = YES;
	NSManagedObjectContext *context = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Activity"];
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"start" ascending:NO];
	fetchRequest.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"recording == 0"];
	self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:@"activities"];
}

- (IBAction)refreshing:(UIRefreshControl *)sender {
	//[self uploadNewActivities];
	[self fetchActivityList];
}

- (void)uploadNewActivities
{
	__block __typeof__(self) blockSelf = self;
	NSManagedObjectContext *context = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Activity"];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(tracktivityID == nil) AND (recording == 0)"];
	NSArray *newActivities = [context executeFetchRequest:fetchRequest error:nil];
	for (Activity *newActivity in newActivities) {
		[RKObjectManager.sharedManager postObject:newActivity path:nil parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
			Activity *activity = (Activity *) mappingResult.firstObject;
			NSLog(@"successfully uploaded activity with newly assigned tracktivity ID: %@", activity.tracktivityID);
		} failure:^(RKObjectRequestOperation *operation, NSError *error) {
			[blockSelf operationFailedWithError:error];
		}];
	}
}

- (void)fetchActivityList
{
	__block __typeof__(self) blockSelf = self;
	RKObjectManager *manager = [RKObjectManager sharedManager];
	NSDictionary *pathObject = [NSDictionary dictionaryWithObject:@"hendrik" forKey:@"username"];
	[manager getObjectsAtPathForRouteNamed:@"userActivityIds" object:pathObject parameters:nil
								   success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
		NSArray *activityIDs = mappingResult.array;
		[blockSelf downloadNewActivities:activityIDs];
		//[blockSelf deleteActivitiesNotIncludedInList:activityIDs];
	} failure:^(RKObjectRequestOperation *operation, NSError *error) {
		[blockSelf operationFailedWithError:error];
	}];
}

// activityIDs must be an array of ThinActivity objects
- (void)downloadNewActivities:(NSArray *)activityIDs
{
	__block __typeof__(self) blockSelf = self;
	NSManagedObjectContext *context = self.fetchedResultsController.managedObjectContext;
	for (ThinActivity *thinActivity in activityIDs) {
		NSString *tracktivityID = thinActivity.tracktivityID;
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"tracktivityID == %@", tracktivityID];
		if ([context countForEntityForName:@"Activity" predicate:predicate error:nil] == 0) {
			NSLog(@"Loading activity %@ from the server ...", tracktivityID);
			Activity *activity = [context insertNewObjectForEntityForName:@"Activity"];
			activity.recording = @YES;
			activity.tracktivityID = tracktivityID;
			[[RKObjectManager sharedManager] getObject:activity path:nil parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
				NSLog(@"successfully fetched activity: %@", tracktivityID);
				Activity *fetchedActivity = (Activity *) mappingResult.firstObject;
				fetchedActivity.recording = @NO;
			} failure:^(RKObjectRequestOperation *operation, NSError *error) {
				[blockSelf operationFailedWithError:error];
			}];
		} else {
			NSLog(@"The activity %@ was already loaded from the server.", tracktivityID);
		}
	}
}

- (void)deleteActivitiesNotIncludedInList:(NSArray *)activityIDs
{
	NSManagedObjectContext *context = [[RKManagedObjectStore defaultStore] newChildManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType tracksChanges:YES];
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Activity"];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"tracktivityID != nil"];
	NSArray *activities = [context executeFetchRequest:fetchRequest error:nil];
	for (Activity *activity in activities) {
		NSDictionary *testDict = [NSDictionary dictionaryWithObject:activity.tracktivityID forKey:@"id"];
		if (![activityIDs containsObject:testDict]) {
			NSLog(@"Deleting activity %@ now.", activity.tracktivityID);
			[context deleteObject:activity];
		}
	}
	if ([context hasChanges]) {
		NSError *error;
		BOOL success = [context saveToPersistentStore:&error];
		if (!success) RKLogWarning(@"Failed saving managed object context: %@", error);
	}
}

- (void)operationFailedWithError:(NSError *)error
{
	RKLogWarning(@"Operation failed with an error: %@", error);
	NSString *localizedErrorMessage = [error.userInfo objectForKey:@"NSLocalizedDescription"];
	NSString *cancelButtonTitle = NSLocalizedString(@"AlertViewOK", @"alert view ok button label");
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:localizedErrorMessage delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles: nil];
	[alertView show];
}

- (void)saveContext
{
	NSError *error = nil;
	BOOL success = [RKManagedObjectStore.defaultStore.mainQueueManagedObjectContext saveToPersistentStore:&error];
	if (!success) RKLogWarning(@"Failed saving managed object context: %@", error);
}

@end
