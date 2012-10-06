//
//  FinishActivityViewController.m
//  LocationTest
//
//  Created by Hendrik on 01.10.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "FinishActivityViewController.h"
#import "Activity.h"
#import "ActivityType.h"

@interface FinishActivityViewController ()
@property (weak, nonatomic) IBOutlet UIPickerView *activityTypePicker;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (nonatomic, strong) NSDictionary *localizedLabels;
@end

@implementation FinishActivityViewController

@synthesize activityTypePicker = _activityTypePicker;
@synthesize activity = _activity;
@synthesize wrappedTrack = _wrappedTrack;
@synthesize localizedLabels = _localizedLabels;

- (NSDictionary *)localizedLabels
{
	if (_localizedLabels == nil) {
		_localizedLabels = [ActivityType localizedLabels];
	}
	return _localizedLabels;
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

- (void)setWrappedTrack:(WrappedTrack *)wrappedTrack
{
	NSAssert([wrappedTrack isKindOfClass:[Activity class]], @"The given wrapped track needs to be an activity.");
	_wrappedTrack = wrappedTrack;
	self.activity = (Activity *) wrappedTrack;
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

- (IBAction)finishButtonPressed:(UIButton *)sender
{
	self.activity.name = self.nameTextField.text;
	if (self.activity.type < 0) {
		self.activity.type = [self.localizedLabels objectForKey:[NSNumber numberWithInt:0]];
	}
	[self.delegate finishActivityViewController:self didFinishActivity:self.activity];
}

#pragma mark UIPickerViewDelegate Methods

- (NSString *)pickerView:(UIPickerView *)pickerView
			 titleForRow:(NSInteger)row
			forComponent:(NSInteger)component
{
	return [self.localizedLabels objectForKey:[NSNumber numberWithInt:row]];
}

- (void)pickerView:(UIPickerView *)pickerView
	  didSelectRow:(NSInteger)row
	   inComponent:(NSInteger)component
{
	self.activity.type = [NSNumber numberWithInt:row];
}

#pragma mark UIPickerViewDataSource Methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
	return self.localizedLabels.count;
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
