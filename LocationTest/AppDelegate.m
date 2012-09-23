//
//  AppDelegate.m
//  LocationTest
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
#import <RestKit/RestKit.h>

@interface AppDelegate ()
@property (nonatomic, strong) GPXParser *gpxParser;
@property (nonatomic, strong) UITabBarController *tbc;
@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize gpxParser = _gpxParser;
@synthesize tbc = _tbc;

- (GPXParser *)gpxParser
{
	if (_gpxParser == nil) {
		_gpxParser = [[GPXParser alloc] initWithPersistentStoreCoordinator:self.persistentStoreCoordinator];
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

- (void)showImportMessageForURL:(NSURL *)url
{
	NSString *alertTitle = NSLocalizedString(@"FileImportTitle", @"File import title");
	NSString *alertMessage = [NSString stringWithFormat:NSLocalizedString(@"FileImportMessage", @"File import message"), url.lastPathComponent];
	UIAlertView *importSuccessMessage = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:self cancelButtonTitle:NSLocalizedString(@"AlertBtnOk", @"Alert Button, Ok") otherButtonTitles:NSLocalizedString(@"AlertBtnShowOnMap", @"Alert Button, show on map"), nil];
	[importSuccessMessage show];
}

- (void)parseGPXFile:(NSURL *)url
{
	[self.gpxParser addObserver:self.tbc forKeyPath:@"parseProgress" options:NSKeyValueObservingOptionNew context:NULL];
	if ([self.gpxParser parseGPXFile:url]) {
		// Delete the file from the inbox directory. It's stored (externally) in Core Data now.
		NSError *fileManagerError;
		if (![[NSFileManager defaultManager] removeItemAtURL:url error:&fileManagerError]) {
			NSLog(@"An error occured trying to delete a file: %@", fileManagerError);
		}
		// Inform user that the file has been successfully imported.
		[self performSelectorOnMainThread:@selector(showImportMessageForURL:) withObject:url waitUntilDone:NO];
	} else {
		NSLog(@"The file %@ could not be parsed without errors.", url.lastPathComponent);
	}
}

#pragma mark UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	__block __typeof__(self) blockSelf = self;
	[self.tbc dismissViewControllerAnimated:YES completion:^{
		if (alertView.firstOtherButtonIndex == buttonIndex) {
			Track *importedTrack = blockSelf.gpxParser.parsedTrack;
			if (importedTrack != nil) {
				UINavigationController *navc = (UINavigationController *) blockSelf.tbc.viewControllers.lastObject;
				blockSelf.tbc.selectedViewController = navc;
				[navc popToRootViewControllerAnimated:NO];
				SegmentedTrackViewController *stvc = (SegmentedTrackViewController *) navc.topViewController;
				[stvc setCurrentViewControllerWithIndex:kRouteViewController];
				NSIndexPath *cellIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
				UITableViewController *tvc = stvc.currentTableViewController;
				[tvc performSegueWithIdentifier:@"Show Route Details"
										 sender:[tvc.tableView cellForRowAtIndexPath:cellIndexPath]];
			}
		}
	}];
}

#pragma mark UIApplicationDelegate Methods

- (BOOL)application:(UIApplication *)application
			openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
		 annotation:(id)annotation
{
	if ([url.pathExtension isEqualToString:@"gpx"]) {
		[self.tbc performSegueWithIdentifier:@"Show Import View" sender:url];
		[self performSelectorInBackground:@selector(parseGPXFile:) withObject:url];
		return YES;
	}
	return NO;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
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
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
			// Replace this implementation with code to handle the error appropriately.
			// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

- (void)objectContextDidSave:(NSNotification *)notification
{
	if (self.managedObjectContext == notification.object) return;
    [self.managedObjectContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:) withObject:notification waitUntilDone:YES];
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
		// register for save actions on (other) contexts
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(objectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
    }
    return __managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"LocationTest.sqlite"];
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:*/
		[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
         
         /* Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
