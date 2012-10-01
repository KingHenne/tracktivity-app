//
//  FinishActivityViewController.m
//  LocationTest
//
//  Created by Hendrik on 01.10.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "FinishActivityViewController.h"

@interface FinishActivityViewController ()
@property (weak, nonatomic) IBOutlet UIPickerView *activityTypePicker;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (nonatomic, strong) NSArray *activityTypes;
@end

@implementation FinishActivityViewController

@synthesize activityTypePicker = _activityTypePicker;
@synthesize activityTypes = _activityTypes;
@synthesize activity = _activity;
@synthesize track = _track;

- (NSArray *)activityTypes
{
	if (_activityTypes == nil) {
		_activityTypes = [NSArray arrayWithObjects:
						  NSLocalizedString(@"activity.cycling", @"activity type cycling"),
						  NSLocalizedString(@"activity.running", @"activity type running"),
						  NSLocalizedString(@"activity.hiking", @"activity type hiking"),
						  nil];
	}
	return _activityTypes;
}

- (void)updateTextFieldText
{
	if (self.activity == nil || self.nameTextField == nil) return;
	if (self.activity.name) {
		self.nameTextField.text = self.activity.name;
	} else {
		self.nameTextField.text = [NSDateFormatter localizedStringFromDate:self.activity.start dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
	}
}


- (void)setTrack:(Track *)track
{
	NSAssert([track isKindOfClass:[Activity class]], @"The given track needs to be an activity.");
	_track = track;
	self.activity = (Activity *) track;
}

- (void)setActivity:(Activity *)activity
{
	_activity = activity;
	[self updateTextFieldText];
}

- (void)setNameTextField:(UITextField *)nameTextField
{
	_nameTextField = nameTextField;
	[self updateTextFieldText];
}

- (IBAction)handleTap:(UITapGestureRecognizer *)sender
{
	if (sender.state == UIGestureRecognizerStateEnded) {
		[self.nameTextField resignFirstResponder];
	}
}

#pragma mark UIPickerViewDelegate Methods

- (NSString *)pickerView:(UIPickerView *)pickerView
			 titleForRow:(NSInteger)row
			forComponent:(NSInteger)component
{
	return [self.activityTypes objectAtIndex:row];
}

#pragma mark UIPickerViewDataSource Methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
	return self.activityTypes.count;
}

#pragma mark UIViewController Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
	[self setActivityTypePicker:nil];
	[self setNameTextField:nil];
	[super viewDidUnload];
}
@end
