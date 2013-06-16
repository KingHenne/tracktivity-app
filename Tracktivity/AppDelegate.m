//
//  AppDelegate.m
//  Tracktivity
//
//  Created by Hendrik Liebau on 14.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "AppDelegate.h"
#import "TrackingManager.h"
#import "FileHelper.h"
#import "GPXParser.h"
#import "TrackTableViewController.h"
#import "RouteTableViewController.h"
#import "TrackViewController.h"
#import "SegmentedTrackViewController.h"
#import "Activity.h"
#import "ActivityType.h"
#import "Track.h"
#import "Segment.h"
#import "Waypoint.h"
#import <RestKit/RestKit.h>
#import <RestKit/RKISO8601DateFormatter.h>
//#import <WFConnector/WFConnector.h>

@interface AppDelegate ()
@property (nonatomic, strong) GPXParser *gpxParser;
@property (nonatomic, strong) UITabBarController *tbc;
//@property (retain, nonatomic) WFHeartrateConnection *hrConnection;
//@property (retain, nonatomic) WFBikeSpeedCadenceConnection *scConnection;
@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize gpxParser = _gpxParser;
@synthesize tbc = _tbc;
//@synthesize hrConnection = _hrConnection;
//@synthesize scConnection = _scConnection;

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

- (void)initializeRestKit
{
	// Log all HTTP traffic with request and response bodies
	RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
	
	// Log debugging info about Core Data
	RKLogConfigureByName("RestKit/CoreData", RKLogLevelDebug);
	
	NSError *error = nil;
	NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] mutableCopy];
	RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
	
	// Initialize the Core Data stack
	[managedObjectStore createPersistentStoreCoordinator];
	
	// Initialize object store
	BOOL success = RKEnsureDirectoryExistsAtPath(RKApplicationDataDirectory(), &error);
	if (! success) {
		RKLogError(@"Failed to create Application Data Directory at path '%@': %@", RKApplicationDataDirectory(), error);
	}
#ifdef RESTKIT_GENERATE_SEED_DB
	NSString *seedDatabasePath = nil;
	NSString *databasePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"RKSeedDatabase.sqlite"];
#else
	NSString *seedDatabasePath = [[NSBundle mainBundle] pathForResource:@"RKSeedDatabase" ofType:@"sqlite"];
	NSString *databasePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Tracktivity.sqlite"];
#endif
	
	NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:databasePath fromSeedDatabaseAtPath:seedDatabasePath withConfiguration:nil options:nil error:&error];
	if (! persistentStore) {
		RKLogError(@"Failed adding persistent store at path '%@': %@", databasePath, error);
	}
	
	[managedObjectStore createManagedObjectContexts];
	
	// Set the default store shared instance
	[RKManagedObjectStore setDefaultStore:managedObjectStore];
	
	NSURL *apiEndpoint = [NSURL URLWithString:@"http://mackie-messer.local:8080/api"];
	RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:apiEndpoint];
	objectManager.managedObjectStore = managedObjectStore;
	
	// Send user credentials as basic auth.
	// TODO: replace this with NSUserDefaults values filled with a login view.
	[objectManager.HTTPClient setAuthorizationHeaderWithUsername:@"hendrik" password:@"boerrek"];
	
	// Set the default manager shared instance
	[RKObjectManager setSharedManager:objectManager];
	
	// Enable automatic network activity indicator management.
	[AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
	
	// Configure a (serialization) mapping for the Activity class and its relationships.
	
	RKEntityMapping *activityMapping = [RKEntityMapping mappingForEntityForName:@"Activity" inManagedObjectStore:managedObjectStore];
	RKEntityMapping *trackMapping = [RKEntityMapping mappingForEntityForName:@"Track" inManagedObjectStore:managedObjectStore];
	RKEntityMapping *segmentMapping = [RKEntityMapping mappingForEntityForName:@"Segment" inManagedObjectStore:managedObjectStore];
	RKEntityMapping *pointMapping = [RKEntityMapping mappingForEntityForName:@"Waypoint" inManagedObjectStore:managedObjectStore];
	RKEntityMapping *activityTypeMapping = [RKEntityMapping mappingForEntityForName:@"ActivityType" inManagedObjectStore:managedObjectStore];
	
	[pointMapping addAttributeMappingsFromDictionary:@{
	 @"time":	@"time",
     @"lat":	@"latitude",
     @"lon":	@"longitude",
     @"ele":	@"elevation"}];
	
	[segmentMapping addRelationshipMappingWithSourceKeyPath:@"points" mapping:pointMapping];
	[trackMapping addRelationshipMappingWithSourceKeyPath:@"segments" mapping:segmentMapping];
	
	[activityMapping addAttributeMappingsFromDictionary:@{
	 @"id":			@"tracktivityID",
     @"name":		@"name",
     @"created":	@"start"}];
	activityMapping.identificationAttributes = @[ @"tracktivityID" ];
	
	[activityMapping addRelationshipMappingWithSourceKeyPath:@"track" mapping:trackMapping];
	activityTypeMapping.identificationAttributes = @[ @"stringValue" ];
	[activityMapping addRelationshipMappingWithSourceKeyPath:@"type" mapping:activityTypeMapping];
	
#ifdef RESTKIT_GENERATE_SEED_DB
	// TODO: set a different activityTypeMapping here
	// Create a seed database with all activity types.
	RKManagedObjectSeeder *objectSeeder = [RKManagedObjectSeeder objectSeederWithObjectManager:objectManager];
	[objectSeeder seedObjectsFromFile:@"ActivityTypes.json" withObjectMapping:activityTypeMapping];
	// Finalize the seeding operation and output a helpful informational message
    [objectSeeder finalizeSeedingAndExit];
#endif
	
	// Set the preferred date formatter.
	RKISO8601DateFormatter *dateFormatter = [RKISO8601DateFormatter new];
	dateFormatter.format = RKISO8601DateFormatCalendar;
	dateFormatter.includeTime = YES;
	[RKObjectMapping setPreferredDateFormatter:dateFormatter];
	
	// Globally use JSON as the wire format for POST/PUT operations.
	objectManager.requestSerializationMIMEType = RKMIMETypeJSON;
}

/*- (void)initializeAccessories
{
	hardwareConnector = [WFHardwareConnector sharedConnector];
    
    // Determine support for BTLE.
    if (hardwareConnector.hasBTLESupport) {
		hardwareConnector.delegate = self;
		hardwareConnector.sampleRate = 0.5;  // sample rate 500 ms, or 2 Hz.
		
        [hardwareConnector enableBTLE:TRUE];
		
		// Set HW Connector to call hasData only when new data is available.
		[hardwareConnector setSampleTimerDataCheck:YES];
		
		// Listen for changes made to the accessory settings.
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults addObserver:self forKeyPath:BTLE_HR_ENABLED options:NSKeyValueObservingOptionNew context:NULL];
		[userDefaults addObserver:self forKeyPath:BTLE_SC_ENABLED options:NSKeyValueObservingOptionNew context:NULL];
		
		// Set up the connections if enabled via settings.
		if ([userDefaults boolForKey:BTLE_HR_ENABLED]) {
			[self requestHrConnection];
		}
		if ([userDefaults boolForKey:BTLE_SC_ENABLED]) {
			[self requestScConnection];
		}
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
	if ([keyPath isEqualToString:BTLE_HR_ENABLED]) {
		BOOL enabled = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		if (enabled) {
			[self requestHrConnection];
		} else {
			[self.hrConnection disconnect];
		}
	} else if ([keyPath isEqualToString:BTLE_SC_ENABLED]) {
		BOOL enabled = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		if (enabled) {
			[self requestScConnection];
		} else {
			[self.scConnection disconnect];
		}
	}
}

- (void)requestHrConnection
{
	NSArray* connections = [hardwareConnector getSensorConnections:WF_SENSORTYPE_HEARTRATE];
	self.hrConnection = ([connections count]>0) ? (WFHeartrateConnection *)[connections objectAtIndex:0] : nil;
	if (self.hrConnection == nil) {
		WFConnectionParams *params = [hardwareConnector.settings connectionParamsForSensorType:WF_SENSORTYPE_HEARTRATE];
		params.networkType = WF_NETWORKTYPE_BTLE;
		self.hrConnection = (WFHeartrateConnection *)[hardwareConnector requestSensorConnection:params];
	}
	self.hrConnection.delegate = self;
}

- (void)requestScConnection
{
	NSArray* connections = [hardwareConnector getSensorConnections:WF_SENSORTYPE_BIKE_SPEED_CADENCE];
	self.scConnection = ([connections count]>0) ? (WFBikeSpeedCadenceConnection *)[connections objectAtIndex:0] : nil;
	if (self.scConnection == nil) {
		WFConnectionParams *params = [hardwareConnector.settings connectionParamsForSensorType:WF_SENSORTYPE_BIKE_SPEED_CADENCE];
		params.networkType = WF_NETWORKTYPE_BTLE;
		self.scConnection = (WFBikeSpeedCadenceConnection *)[hardwareConnector requestSensorConnection:params];
	}
	self.scConnection.delegate = self;
}*/

- (void)saveContext
{
	NSError *error = nil;
	BOOL success = [RKManagedObjectStore.defaultStore.mainQueueManagedObjectContext saveToPersistentStore:&error];
	if (!success) RKLogWarning(@"Failed saving managed object context: %@", error);
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
	[self initializeRestKit];
	//[self initializeAccessories];
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

#pragma mark HardwareConnectorDelegate Implementation

/*- (void)hardwareConnector:(WFHardwareConnector *)hwConnector connectedSensor:(WFSensorConnection *)connectionInfo
{
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:connectionInfo forKey:@"connectionInfo"];
	[[NSNotificationCenter defaultCenter] postNotificationName:WF_NOTIFICATION_SENSOR_CONNECTED object:nil userInfo:userInfo];
}

- (void)hardwareConnector:(WFHardwareConnector *)hwConnector disconnectedSensor:(WFSensorConnection *)connectionInfo
{
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:connectionInfo forKey:@"connectionInfo"];
	[[NSNotificationCenter defaultCenter] postNotificationName:WF_NOTIFICATION_SENSOR_DISCONNECTED object:nil userInfo:userInfo];
}

- (void)hardwareConnector:(WFHardwareConnector *)hwConnector stateChanged:(WFHardwareConnectorState_t)currentState
{
	BOOL connected = (currentState & WF_HWCONN_STATE_BT40_ENABLED) ? TRUE : FALSE;
	if (connected)
	{
        [[NSNotificationCenter defaultCenter] postNotificationName:WF_NOTIFICATION_HW_CONNECTED object:nil];
	}
	else
	{
        [[NSNotificationCenter defaultCenter] postNotificationName:WF_NOTIFICATION_HW_DISCONNECTED object:nil];
	}
}

- (void)hardwareConnectorHasData
{
	[[NSNotificationCenter defaultCenter] postNotificationName:WF_NOTIFICATION_SENSOR_HAS_DATA object:nil];
}

#pragma mark WFSensorConnectionDelegate Implementation

- (void)connectionDidTimeout:(WFSensorConnection*)connectionInfo
{
	connectionInfo.delegate = nil;
	if (connectionInfo.sensorType == WF_SENSORTYPE_HEARTRATE) {
		self.hrConnection = nil;
	} else if (connectionInfo.sensorType == WF_SENSORTYPE_BIKE_SPEED_CADENCE) {
		self.scConnection = nil;
	}
}

- (void)connection:(WFSensorConnection*)connectionInfo stateChanged:(WFSensorConnectionStatus_t)connState
{
	NSLog(@"SENSOR CONNECTION STATE CHANGED: connState = %d (IDLE=%d)", connState, WF_SENSOR_CONNECTION_STATUS_IDLE);
    
    // Check for a valid connection.
    if (connectionInfo.isValid && connectionInfo.isConnected)
    {
        // Process post-connection setup.
		[[WFHardwareConnector sharedConnector].settings saveConnectionInfo:connectionInfo];
    }
}*/

@end
