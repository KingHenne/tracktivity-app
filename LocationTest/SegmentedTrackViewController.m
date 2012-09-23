//
//  SegmentedControlViewController.m
//  LocationTest
//
//  Created by Hendrik on 05.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "SegmentedTrackViewController.h"
#import "ActivityTableViewController.h"
#import "Activity.h"

@interface SegmentedTrackViewController ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *trackTypeControl;
@property (strong, nonatomic) UIViewController *currentViewController;
@property (strong, nonatomic) NSArray *childViewControllers;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *refreshButton;
@end

@implementation SegmentedTrackViewController

@synthesize trackTypeControl = _trackTypeControl;
@synthesize refreshButton = _refreshButton;
@synthesize childViewControllers = _childViewControllers;

- (NSArray *)childViewControllers
{
	if (_childViewControllers == nil) {
		UIViewController *activityVC = [self.storyboard instantiateViewControllerWithIdentifier:@"Activity Table View Controller"];
		UIViewController *routeVC = [self.storyboard instantiateViewControllerWithIdentifier:@"Route Table View Controller"];
		_childViewControllers = [NSArray arrayWithObjects:activityVC, routeVC, nil];
	}
	return _childViewControllers;
}

- (UITableViewController *)currentTableViewController
{
	if ([self.currentViewController isKindOfClass:[UITableViewController class]]) {
		return (UITableViewController *) self.currentViewController;
	}
	return nil;
}

- (void)setCurrentViewController:(UIViewController *)currentViewController
{
	[_currentViewController.view removeFromSuperview];
	currentViewController.view.frame = self.view.bounds;
	[self.view addSubview:currentViewController.view];
	_currentViewController = currentViewController;
}

- (void)setCurrentViewControllerWithIndex:(int)viewControllerIndex
{
	if (viewControllerIndex == kActivityViewController || viewControllerIndex == kRouteViewController) {
		self.trackTypeControl.selectedSegmentIndex = viewControllerIndex;
		self.currentViewController = [self.childViewControllers objectAtIndex:viewControllerIndex];
	}
	if (viewControllerIndex == kActivityViewController) {
		self.navigationItem.leftBarButtonItem = self.refreshButton;
	} else {
		self.navigationItem.leftBarButtonItem = nil;
	}
}

- (IBAction)trackTypeChanged:(UISegmentedControl *)sender
{
	self.title = [sender titleForSegmentAtIndex:sender.selectedSegmentIndex];
	[self setCurrentViewControllerWithIndex:sender.selectedSegmentIndex];
}

- (IBAction)trashButtonPressed:(UIBarButtonItem *)sender
{
	NSString *cancelButtonTitle = NSLocalizedString(@"ActionSheetCancel", @"action sheet cancel button label");
	NSString *destructiveButtonTitle = [NSString stringWithFormat:NSLocalizedString(@"ActionSheetDeleteTracksFormat", @"action sheet button label for deleting activities"), self.title];
	NSString *otherButtonTitle = NSLocalizedString(@"ActionSheetDeleteThumbnails", @"action sheet button label for deleting thumbnails");
	UIActionSheet *deleteActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:cancelButtonTitle destructiveButtonTitle:destructiveButtonTitle otherButtonTitles:otherButtonTitle, nil];
	[deleteActionSheet showFromBarButtonItem:sender animated:YES];
}

- (IBAction)refreshButtonPressed:(UIBarButtonItem *)sender
{
	[self uploadNewActivities];
	[self downloadNewActivities];
}

- (void)uploadNewActivities
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"tracktivityID = nil"];
	NSArray *newActivities = [Activity findAllWithPredicate:predicate];
	for (Activity *newActivity in newActivities) {
		[[RKObjectManager sharedManager] postObject:newActivity delegate:self];
	}
}

- (void)downloadNewActivities
{
	[[[RKObjectManager sharedManager] client] get:@"/users/hendrik/activities" delegate:self];
}

#pragma mark UIActionSheetDelegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == actionSheet.destructiveButtonIndex) {
		[self.currentViewController performSelector:@selector(deleteTracks)];
	} else if (buttonIndex == actionSheet.firstOtherButtonIndex) {
		[self.currentViewController performSelector:@selector(deleteThumbnails)];
	}
}

#pragma mark RestKit Delegate Methods

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response
{
	if (response.isJSON) {
		NSError * error;
		NSDictionary *responseBody = [response parsedBody:&error];
		if (responseBody) {
			NSArray *activities = [responseBody valueForKey:@"activities"];
			for (NSDictionary *activity in activities) {
				NSString *tracktivityID = [[activity valueForKey:@"id"] stringValue];
				if (tracktivityID && [Activity findByPrimaryKey:tracktivityID] == nil) {
					NSLog(@"Loading activity %@ from the server...", tracktivityID);
					NSString *path = [NSString stringWithFormat:@"/activities/%@", tracktivityID];
					[[RKObjectManager sharedManager] loadObjectsAtResourcePath:path delegate:self];
				}
			}
		} else {
			NSLog(@"Error parsing response: %@, %@", error, [error userInfo]);
		}
	}
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error
{
	NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
}

#pragma mark UIViewController Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	for (UIViewController *childVC in self.childViewControllers) {
		[self addChildViewController:childVC];
	}
	
	NSInteger segmentIndex = self.trackTypeControl.selectedSegmentIndex;
	
	UIViewController *vc = [self.childViewControllers objectAtIndex:segmentIndex];
    vc.view.frame = self.view.bounds;
    [self.view addSubview:vc.view];
    _currentViewController = vc;
	
	self.title = [self.trackTypeControl titleForSegmentAtIndex:segmentIndex];
}

- (void)viewDidUnload
{
    // Release any retained subviews of the main view.
	[self setTrackTypeControl:nil];
	[self setRefreshButton:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
