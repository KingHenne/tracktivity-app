//
//  AppDelegate.m
//  Tracktivity
//
//  Created by Hendrik Liebau on 14.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "AppDelegate.h"
#import "TrackingManager.h"
#import <CoreData/CoreData.h>
#import "FileHelper.h"
#import "GPXParser.h"
#import "TrackTableViewController.h"
#import "TrackViewController.h"
#import "SegmentedTrackViewController.h"
#import "Activity.h"
#import "ActivityType.h"
#import "Track.h"
#import "Segment.h"
#import "Waypoint.h"
#import <RestKit/RestKit.h>
#import <RestKit/ISO8601DateFormatter.h>

@interface AppDelegate ()
@property (nonatomic, strong) GPXParser *gpxParser;
@property (nonatomic, strong) UITabBarController *tbc;
@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize gpxParser = _gpxParser;
@synthesize tbc = _tbc;

- (GPXParser *)gpxParser
{
	if (_gpxParser == nil) {
		_gpxParser = [[GPXParser alloc] init];
	}
	return _gpxParser;
}

- (UITabBarController *)tbc
{
	if (_tbc == nil) {
		_tbc = (UITabBarController *) self.window.rootViewController;
	}
	return _tbc;
}

- (void)showImportSuccessMessageForURL:(NSURL *)url
{
	NSString *alertTitle = NSLocalizedString(@"FileImportTitle", @"File import title");
	NSString *alertMessage = [NSString stringWithFormat:NSLocalizedString(@"FileImportMessage", @"File import message"), url.lastPathComponent];
	UIAlertView *importSuccessMessage = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:self cancelButtonTitle:NSLocalizedString(@"AlertBtnOk", @"Alert Button, Ok") otherButtonTitles:NSLocalizedString(@"AlertBtnShowOnMap", @"Alert Button, show on map"), nil];
	[importSuccessMessage show];
}

- (void)showImportFailureMessageForURL:(NSURL *)url
{
	NSString *alertTitle = NSLocalizedString(@"FileImportFailedTitle", @"File import failed title");
	NSString *alertMessage = [NSString stringWithFormat:NSLocalizedString(@"FileImportFailedMessage", @"File import failed message"), url.lastPathComponent];
	UIAlertView *importFailureMessage = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:self cancelButtonTitle:NSLocalizedString(@"AlertBtnOk", @"Alert Button, Ok") otherButtonTitles: nil];
	[importFailureMessage show];
}

- (void)parseGPXFile:(NSURL *)url
{
	[self.gpxParser addObserver:self.tbc forKeyPath:@"parseProgress" options:NSKeyValueObservingOptionNew context:NULL];
	if ([self.gpxParser parseGPXFile:url]) {
		if ([url isFileURL]) {
			// Delete the file from the inbox directory. It's stored (externally) in Core Data now.
			NSError *fileManagerError;
			if (![[NSFileManager defaultManager] removeItemAtURL:url error:&fileManagerError]) {
				NSLog(@"An error occured trying to delete a file: %@", fileManagerError);
			}
		}
		// Inform user that the file has been successfully imported.
		[self performSelectorOnMainThread:@selector(showImportSuccessMessageForURL:) withObject:url waitUntilDone:NO];
	} else {
		NSLog(@"The file %@ could not be parsed without errors.", url.lastPathComponent);
		// Inform user that the file could not be imported.
		[self performSelectorOnMainThread:@selector(showImportFailureMessageForURL:) withObject:url waitUntilDone:NO];
	}
	[self.gpxParser removeObserver:self.tbc forKeyPath:@"parseProgress"];
}

#pragma mark UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	__block __typeof__(self) blockSelf = self;
	[self.tbc dismissViewControllerAnimated:YES completion:^{
		if (alertView.firstOtherButtonIndex == buttonIndex) {
			Route *importedRoute = blockSelf.gpxParser.parsedRoute;
			if (importedRoute != nil) {
				UINavigationController *navc = (UINavigationController *) blockSelf.tbc.viewControllers.lastObject;
				blockSelf.tbc.selectedViewController = navc;
				[navc popToRootViewControllerAnimated:NO];
				SegmentedTrackViewController *stvc = (SegmentedTrackViewController *) navc.topViewController;
				[stvc setCurrentViewControllerWithIndex:kRouteViewController];
				TrackTableViewController *tvc = stvc.currentViewController;
				[[NSNotificationCenter defaultCenter] addObserver:tvc
														 selector:@selector(displayImportedTrackNotification:)
															 name:DisplayImportedTrackNotification
														   object:nil];
				[[NSNotificationCenter defaultCenter] postNotificationName:DisplayImportedTrackNotification object:importedRoute];
			}
		}
	}];
}

#pragma mark RKManagedObjectStoreDelegate Methods

- (void)managedObjectStore:(RKManagedObjectStore *)objectStore didFailToCreatePersistentStoreCoordinatorWithError:(NSError *)error
{
	[objectStore deletePersistentStore];
}

#pragma mark UIApplicationDelegate Methods

- (BOOL)application:(UIApplication *)application
			openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
		 annotation:(id)annotation
{
	[self.tbc performSegueWithIdentifier:@"Show Import View" sender:url];
	[self performSelectorInBackground:@selector(parseGPXFile:) withObject:url];
	return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
	
	// Activate logging.
//	RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
//	RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelTrace);
//  RKLogConfigureByName("RestKit/CoreData", RKLogLevelTrace);
	
	// Initialize RestKit.
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURLString:@"http://mackie-messer.local:8080/api"];
	
    // Enable automatic network activity indicator management.
    objectManager.client.requestQueue.showsNetworkActivityIndicatorWhenBusy = YES;
	
	// Initialize object store
#ifdef RESTKIT_GENERATE_SEED_DB
	NSString *seedDatabaseName = nil;
	NSString *databaseName = RKDefaultSeedDatabaseFileName;
#else
	NSString *seedDatabaseName = RKDefaultSeedDatabaseFileName;
	NSString *databaseName = @"CoreData.sqlite";
#endif
	
    // Initialize object store.
	RKManagedObjectStore *objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:databaseName usingSeedDatabaseName:seedDatabaseName managedObjectModel:nil delegate:self];
	objectManager.objectStore = objectStore;
	
	// Uncomment this line for one run if you want to reset the database.
	//[objectStore deletePersistentStoreUsingSeedDatabaseName:seedDatabaseName];
	
	// Globally use JSON as the wire format for POST/PUT operations.
	objectManager.serializationMIMEType = RKMIMETypeJSON;
	
	// Grab the reference to the router from the manager.
	RKObjectRouter *router = objectManager.router;
	// Define a resource path for posting activities.
	[router routeClass:[Activity class] toResourcePath:@"/activities" forMethod:RKRequestMethodPOST];
	// Define a resource path for deleting activities.
	[router routeClass:[Activity class] toResourcePath:@"/activities/:tracktivityID" forMethod:RKRequestMethodDELETE];
	
	// Configure a (serialization) mapping for the Activity class and its relationships.
	
	RKManagedObjectMapping *activityMapping = [RKManagedObjectMapping mappingForClass:[Activity class] inManagedObjectStore:objectStore];
	RKManagedObjectMapping *trackMapping = [RKManagedObjectMapping mappingForClass:[Track class] inManagedObjectStore:objectStore];
	RKManagedObjectMapping *segmentMapping = [RKManagedObjectMapping mappingForClass:[Segment class] inManagedObjectStore:objectStore];
	RKManagedObjectMapping *pointMapping = [RKManagedObjectMapping mappingForClass:[Waypoint class] inManagedObjectStore:objectStore];
	RKManagedObjectMapping *activityTypeMapping = [RKManagedObjectMapping mappingForClass:[ActivityType class] inManagedObjectStore:objectStore];
	
	[pointMapping mapKeyPathsToAttributes:
		@"time", @"time",
		@"lat", @"latitude",
		@"lon", @"longitude",
		@"ele", @"elevation", nil];
	
	[segmentMapping mapKeyPath:@"points" toRelationship:@"points" withMapping:pointMapping];
	[trackMapping mapKeyPath:@"segments" toRelationship:@"segments" withMapping:segmentMapping];
	
	[activityMapping mapKeyPathsToAttributes:
		@"id", @"tracktivityID",
		@"name", @"name",
		@"created", @"start", nil];
	activityMapping.primaryKeyAttribute = @"tracktivityID";
	
	[activityMapping mapKeyPath:@"track" toRelationship:@"track" withMapping:trackMapping];
	
	[activityTypeMapping mapKeyOfNestedDictionaryToAttribute:@"stringValue"];
	activityTypeMapping.primaryKeyAttribute = @"stringValue";
	[activityMapping mapKeyPath:@"type" toRelationship:@"type" withMapping:activityTypeMapping];
	
	// Set the object mapping so that the response after posting an activity will be mapped correctly.
	[objectManager.mappingProvider setObjectMapping:activityMapping forResourcePathPattern:@"/activities"];
	// Set the object mapping for getting activities.
	[objectManager.mappingProvider setObjectMapping:activityMapping forResourcePathPattern:@"/activities/:tracktivityID"];
	
	// Adjust the inverse mapping (because of ActivityType).
	RKObjectMapping *inverseMapping = [activityMapping inverseMapping];
	[inverseMapping removeMappingForKeyPath:@"type"];
	[inverseMapping mapKeyPath:@"type.stringValue" toAttribute:@"type"];
	// Set the object mapping for serializing/posting activities.
	[objectManager.mappingProvider setSerializationMapping:inverseMapping forClass:[Activity class]];
	
#ifdef RESTKIT_GENERATE_SEED_DB
	// TODO: set a different activityTypeMapping here
	// Create a seed database with all activity types.
	RKManagedObjectSeeder *objectSeeder = [RKManagedObjectSeeder objectSeederWithObjectManager:objectManager];
	[objectSeeder seedObjectsFromFile:@"ActivityTypes.json" withObjectMapping:activityTypeMapping];
	// Finalize the seeding operation and output a helpful informational message
    [objectSeeder finalizeSeedingAndExit];
#endif
	
	// Set the preferred date formatter.
	ISO8601DateFormatter *dateFormatter = [ISO8601DateFormatter new];
	dateFormatter.format = ISO8601DateFormatCalendar;
	dateFormatter.includeTime = YES;
	[RKObjectMapping setPreferredDateFormatter:dateFormatter];
	
	// DEBUG: Disable SSL certificate validation, because on the local test server we don't have a valid cartificate.
	objectManager.client.disableCertificateValidation = YES;
	
	// Send user credentials as basic auth.
	// TODO: replace this with NSUserDefaults values filled with a login view.
	objectManager.client.authenticationType = RKRequestAuthenticationTypeHTTPBasic;
	objectManager.client.username = @"hendrik";
	objectManager.client.password = @"boerrek";
	
	NSLog(@"number of activity types in database: %d", [ActivityType count:nil]);
	
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	[[TrackingManager sharedTrackingManager] stopUpdatingWithoutRecording];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	[[TrackingManager sharedTrackingManager] stopUpdatingWithoutRecording];
	[self saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Saves changes in the application's managed object context before the application terminates.
	[self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
	if (![RKManagedObjectStore.defaultObjectStore save:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
}

@end
