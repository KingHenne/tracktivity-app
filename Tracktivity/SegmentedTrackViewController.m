//
//  SegmentedControlViewController.m
//  Tracktivity
//
//  Created by Hendrik on 05.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "SegmentedTrackViewController.h"
#import "ActivityTableViewController.h"
#import "Activity.h"

@interface SegmentedTrackViewController ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *trackTypeControl;
@property (strong, nonatomic) TrackTableViewController *currentViewController;
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

- (void)setCurrentViewController:(TrackTableViewController *)currentViewController
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
		self.title = [self.trackTypeControl titleForSegmentAtIndex:viewControllerIndex];
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
	[self setCurrentViewControllerWithIndex:sender.selectedSegmentIndex];
}

- (IBAction)trashButtonPressed:(UIBarButtonItem *)sender
{
	[self.currentViewController trashButtonPressed:sender];
}

- (IBAction)refreshButtonPressed:(UIBarButtonItem *)sender
{
	if ([self.currentViewController respondsToSelector:@selector(refreshButtonPressed:)]) {
		[self.currentViewController performSelector:@selector(refreshButtonPressed:) withObject:sender];
	}
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
	
	TrackTableViewController *vc = [self.childViewControllers objectAtIndex:segmentIndex];
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
