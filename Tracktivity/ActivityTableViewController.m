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

@interface ActivityTableViewController ()
@property (nonatomic, strong) UIBarButtonItem *refreshButton;
@end

@implementation ActivityTableViewController

@synthesize refreshButton = _refreshButton;

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

- (IBAction)refreshButtonPressed:(UIBarButtonItem *)sender
{
	self.refreshButton = sender;
	self.refreshButton.enabled = NO;
	[self uploadNewActivities];
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
			//TODO
		} failure:^(RKObjectRequestOperation *operation, NSError *error) {
			[blockSelf operationFailedWithError:error];
		}];
	}
}

- (void)fetchActivityList
{
	__block __typeof__(self) blockSelf = self;
	RKObjectManager *manager = [RKObjectManager sharedManager];
	RKObjectRequestOperation *operation = [manager appropriateObjectRequestOperationWithObject:nil method:RKRequestMethodGET path:@"users/hendrik/activities" parameters:nil];
	
	[operation setWillMapDeserializedResponseBlock:^id(id deserializedResponseBody) {
		NSLog(@"deserializedResponseBody: %@", deserializedResponseBody);
		return deserializedResponseBody;
	}];
	
	[operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
		NSArray *activityIDs = [mappingResult.dictionary valueForKey:@"activities"];
		if (activityIDs) {
			[blockSelf downloadNewActivities:activityIDs];
			[blockSelf deleteActivitiesNotIncludedInList:activityIDs];
			[blockSelf updateRefreshButton];
		}
	} failure:^(RKObjectRequestOperation *operation, NSError *error) {
		[blockSelf operationFailedWithError:error];
	}];
	
	[manager enqueueObjectRequestOperation:operation];
}

- (void)updateRefreshButton
{
	if (RKObjectManager.sharedManager.operationQueue.operationCount <= 1) {
		self.refreshButton.enabled = YES;
	}
}

// activityIDs must be an array of dictionaries with a key 'id'
- (void)downloadNewActivities:(NSArray *)activityIDs
{
	__block __typeof__(self) blockSelf = self;
	NSManagedObjectContext *context = [[RKManagedObjectStore defaultStore] newChildManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType];
	for (NSDictionary *activity in activityIDs) {
		NSString *tracktivityID = [activity valueForKey:@"id"];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"tracktivityID == %@", tracktivityID];
		if ([context countForEntityForName:@"Activity" predicate:predicate error:nil] == NSNotFound) {
			NSLog(@"Loading activity %@ from the server ...", tracktivityID);
			NSString *path = [NSString stringWithFormat:@"/activities/%@", tracktivityID];
			[[RKObjectManager sharedManager] getObjectsAtPath:path parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
				// TODO: should I do something here?
			} failure:^(RKObjectRequestOperation *operation, NSError *error) {
				[blockSelf operationFailedWithError:error];
			}];
		}
	}
}

- (void)deleteActivitiesNotIncludedInList:(NSArray *)activityIDs
{
	NSManagedObjectContext *context = [[RKManagedObjectStore defaultStore] newChildManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType];
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
	self.refreshButton.enabled = YES;
}

- (void)saveContext
{
	NSError *error = nil;
	BOOL success = [RKManagedObjectStore.defaultStore.mainQueueManagedObjectContext saveToPersistentStore:&error];
	if (!success) RKLogWarning(@"Failed saving managed object context: %@", error);
}

@end
