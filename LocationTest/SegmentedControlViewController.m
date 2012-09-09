//
//  SegmentedControlViewController.m
//  LocationTest
//
//  Created by Hendrik on 05.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "SegmentedControlViewController.h"

@interface SegmentedControlViewController ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *trackTypeControl;
@property (strong, nonatomic) UIViewController *currentViewController;
@property (strong, nonatomic) NSArray *childViewControllers;
@end

@implementation SegmentedControlViewController

@synthesize trackTypeControl = _trackTypeControl;
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
	if (viewControllerIndex == kActivityViewController ||
		viewControllerIndex == kRouteViewController) {
		self.currentViewController = [self.childViewControllers objectAtIndex:viewControllerIndex];
	}
}

- (IBAction)trackTypeChanged:(UISegmentedControl *)sender
{
	self.title = [sender titleForSegmentAtIndex:sender.selectedSegmentIndex];
	[self setCurrentViewControllerWithIndex:sender.selectedSegmentIndex];
}

- (IBAction)trashButtonPressed:(UIBarButtonItem *)sender
{
	[self.currentViewController performSelector:@selector(deleteThumbnails)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	for (UIViewController *childVC in self.childViewControllers) {
		[self addChildViewController:childVC];
	}
	
	UIViewController *vc = [self.childViewControllers objectAtIndex:self.trackTypeControl.selectedSegmentIndex];
    vc.view.frame = self.view.bounds;
    [self.view addSubview:vc.view];
    _currentViewController = vc;
}

- (void)viewDidUnload
{
    // Release any retained subviews of the main view.
	[self setTrackTypeControl:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
