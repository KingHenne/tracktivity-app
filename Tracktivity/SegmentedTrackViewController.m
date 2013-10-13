//
//  SegmentedControlViewController.m
//  Tracktivity
//
//  Created by Hendrik on 05.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "SegmentedTrackViewController.h"
#import "ActivityTableViewController.h"
#import "RouteTableViewController.h"
#import "Activity.h"

@interface SegmentedTrackViewController ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *trackTypeControl;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) TrackTableViewController *currentViewController;
@property (strong, nonatomic) ActivityTableViewController *activityViewController;
@property (strong, nonatomic) RouteTableViewController *routeViewController;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *refreshButton;
@end

@implementation SegmentedTrackViewController

- (void)setCurrentViewControllerWithIndex:(NSUInteger)viewControllerIndex
{
	self.trackTypeControl.selectedSegmentIndex = viewControllerIndex;
	self.title = [self.trackTypeControl titleForSegmentAtIndex:viewControllerIndex];
	
	switch (viewControllerIndex) {
		case kActivityViewController:
			if (self.currentViewController == self.routeViewController) {
				[self addChildViewController:self.activityViewController];
				[self moveToNewController:self.activityViewController];
			}
			break;
		case kRouteViewController:
			if (self.currentViewController == self.activityViewController) {
				[self addChildViewController:self.routeViewController];
				[self moveToNewController:self.routeViewController];
			}
			break;
		default:
			break;
	}
}

-(void)moveToNewController:(TrackTableViewController *) newController {
    [self.currentViewController willMoveToParentViewController:nil];
    [self transitionFromViewController:self.currentViewController
					  toViewController:newController
							  duration:.2
							   options:UIViewAnimationOptionTransitionCrossDissolve
							animations:^{}
							completion:^(BOOL finished) {
								[self.currentViewController removeFromParentViewController];
								UIView *newSubview = newController.view;
								newSubview.translatesAutoresizingMaskIntoConstraints = NO;
								NSDictionary *views = NSDictionaryOfVariableBindings(newSubview);
								[self.containerView addConstraints:
								 [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[newSubview]|"
																		 options:0
																		 metrics:nil
																		   views:views]];
								[self.containerView addConstraints:
								 [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[newSubview]|"
																		 options:0
																		 metrics:nil
																		   views:views]];
								[newController didMoveToParentViewController:self];
								self.currentViewController = newController;
							}];
}

- (IBAction)trackTypeChanged:(UISegmentedControl *)sender
{
	[self setCurrentViewControllerWithIndex:sender.selectedSegmentIndex];
}

- (IBAction)trashButtonPressed:(UIBarButtonItem *)sender
{
	[self.currentViewController trashButtonPressed:sender];
}

#pragma mark UIViewController Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	NSInteger segmentIndex = self.trackTypeControl.selectedSegmentIndex;
	self.title = [self.trackTypeControl titleForSegmentAtIndex:segmentIndex];
	
	self.currentViewController = self.childViewControllers.lastObject;
	self.activityViewController = (ActivityTableViewController *) self.currentViewController;
    self.routeViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Route Table View Controller"];
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
