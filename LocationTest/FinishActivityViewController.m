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
#import <RestKit/RestKit.h>

@interface FinishActivityViewController ()
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITableViewCell *nameCell;
@property (nonatomic, strong) NSArray *activityTypes;
@end

@implementation FinishActivityViewController

@synthesize activity = _activity;
@synthesize wrappedTrack = _wrappedTrack;
@synthesize activityTypes = _activityTypes;

- (NSArray *)activityTypes
{
	if (_activityTypes == nil) {
		_activityTypes = [ActivityType findAllSortedBy:@"displayOrder" ascending:YES];
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

- (IBAction)saveButtonPressed:(id)sender
{
	self.activity.name = self.nameTextField.text;
	if (self.activity.type == nil) {
		self.activity.type = [self.activityTypes objectAtIndex:0];
	}
	[self.delegate finishActivityViewController:self didFinishActivity:self.activity];
}

- (IBAction)abortButtonPressed:(id)sender
{
	NSString *alertTitle = NSLocalizedString(@"AlertTitleDeleteActivity", @"delete activity");
	NSString *alertMessage = NSLocalizedString(@"AlertMessageDeleteActivity", @"delete activity confirm question");
	UIAlertView *abortConfirm = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:self cancelButtonTitle:NSLocalizedString(@"AlertBtnCancel", @"Alert Button, Cancel") otherButtonTitles:NSLocalizedString(@"AlertBtnDelete", @"Alert Button, Delete"), nil];
	[abortConfirm show];
}

#pragma mark UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (alertView.firstOtherButtonIndex == buttonIndex) {
		[self.delegate finishActivityViewController:self didAbortActivity:self.activity];
	}
}

#pragma mark UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

#pragma mark UITableView Delegate/DataSource Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self.nameTextField resignFirstResponder];
	if (indexPath.section == 1) {
		for (int row = 0; row < [tableView numberOfRowsInSection:indexPath.section]; row++) {
			NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:indexPath.section];
			UITableViewCell *cell = [tableView cellForRowAtIndexPath:path];
			if (row == indexPath.row) {
				self.activity.type = [self.activityTypes objectAtIndex:row];
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
				[cell setSelected:NO animated:YES];
			} else {
				cell.accessoryType = UITableViewCellAccessoryNone;
			}
		}
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0) {
		return self.nameCell;
	}
	static NSString *CellIdentifier = @"Activity Type Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
	cell.textLabel.text = [(ActivityType *)[self.activityTypes objectAtIndex:indexPath.row] localizedLabel];
	if (indexPath.row == 0) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	} else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	return cell;
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section) {
		case 1:
			return self.activityTypes.count;
			break;
		default:
			return 1;
	}
}

#pragma mark UIViewController Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload {
	[self setNameTextField:nil];
	[self setNameCell:nil];
	[super viewDidUnload];
}
@end
