//
//  BluetoothViewController.m
//  Tracktivity
//
//  Created by Hendrik on 13.01.13.
//  Copyright (c) 2013 SinnerSchrader. All rights reserved.
//

#import "BluetoothViewController.h"
#import <WFConnector/WFConnector.h>

@interface BluetoothViewController ()

@property (retain, nonatomic) WFHeartrateConnection *hrConnection;
@property (retain, nonatomic) WFBikeSpeedCadenceConnection *scConnection;
@property (weak, nonatomic) IBOutlet UISwitch *hrSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *scSwitch;
@property (weak, nonatomic) IBOutlet UILabel *hrLabel;
@property (weak, nonatomic) IBOutlet UILabel *scLabel;

@end

@implementation BluetoothViewController

@synthesize hrConnection = _hrConnection;
@synthesize scConnection = _scConnection;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	WFHardwareConnector *hardwareConnector = [WFHardwareConnector sharedConnector];
	
	if (hardwareConnector.hasBTLESupport) {
        // update the view
		[self checkConnectionStates];
        [self updateData];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sensorConnected:) name:WF_NOTIFICATION_SENSOR_CONNECTED object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sensorDisconnected:) name:WF_NOTIFICATION_SENSOR_DISCONNECTED object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateData) name:WF_NOTIFICATION_SENSOR_HAS_DATA object:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)sensorConnected:(NSNotification *)notification
{
	WFSensorConnection *connection = (WFSensorConnection *) [notification.userInfo valueForKey:@"connectionInfo"];
	if (connection.sensorType == WF_SENSORTYPE_HEARTRATE) {
		self.hrConnection = (WFHeartrateConnection *) connection;
	} else if (connection.sensorType == WF_SENSORTYPE_BIKE_SPEED_CADENCE) {
		self.scConnection = (WFBikeSpeedCadenceConnection *) connection;
	}
	[self checkConnectionStates];
}

- (void)sensorDisconnected:(NSNotification *)notification
{
	WFSensorConnection *connection = (WFSensorConnection *) [notification.userInfo valueForKey:@"connectionInfo"];
	if (connection.sensorType == WF_SENSORTYPE_HEARTRATE) {
		self.hrConnection = nil;
	} else if (connection.sensorType == WF_SENSORTYPE_BIKE_SPEED_CADENCE) {
		self.scConnection = nil;
	}
	[self checkConnectionStates];
}

- (void)checkConnectionStates
{
	WFSensorConnectionStatus_t hrStatus = WF_SENSOR_CONNECTION_STATUS_IDLE;
	if (self.hrConnection) {
		hrStatus = self.hrConnection.connectionStatus;
	}
	[self setStatus:hrStatus forSwitch:self.hrSwitch andLabel:self.hrLabel];
	NSLog(@"HR Status: %d", hrStatus);
	
	WFSensorConnectionStatus_t scStatus = WF_SENSOR_CONNECTION_STATUS_IDLE;
	if (self.scConnection) {
		scStatus = self.scConnection.connectionStatus;
	}
	[self setStatus:scStatus forSwitch:self.scSwitch andLabel:self.scLabel];
	NSLog(@"SC Status: %d", scStatus);
}

- (void)setStatus:(WFSensorConnectionStatus_t)status
		forSwitch:(UISwitch *)switchBtn
		 andLabel:(UILabel *)label
{
	switch (status)
	{
		case WF_SENSOR_CONNECTION_STATUS_IDLE:
			[self performSelectorOnMainThread:@selector(setSwitchOff:) withObject:switchBtn waitUntilDone:NO];
			label.text = @"—";
			break;
		case WF_SENSOR_CONNECTION_STATUS_CONNECTING:
			label.text = @"…";
			break;
		case WF_SENSOR_CONNECTION_STATUS_CONNECTED:
			[self performSelectorOnMainThread:@selector(setSwitchOn:) withObject:switchBtn waitUntilDone:NO];
			break;
		case WF_SENSOR_CONNECTION_STATUS_DISCONNECTING:
			label.text = @"…";
			break;
        case WF_SENSOR_CONNECTION_STATUS_INTERRUPTED:
			[self performSelectorOnMainThread:@selector(setSwitchOff:) withObject:switchBtn waitUntilDone:NO];
			label.text = @"—";
            break;
	}
}

- (void)setSwitchOn:(UISwitch *)switchBtn
{
	[switchBtn setOn:YES animated:YES];
}

- (void)setSwitchOff:(UISwitch *)switchBtn
{
	[switchBtn setOn:NO animated:YES];
}

- (void)updateData
{
	if (self.hrConnection) {
		WFHeartrateData* hrData = self.hrConnection.getHeartrateData;
		if (hrData != nil) {
			self.hrLabel.text = [hrData formattedHeartrate:YES];
		}
	}
	if (self.scConnection) {
		WFBikeSpeedCadenceData* scData = self.scConnection.getBikeSpeedCadenceData;
		if (scData != nil) {
			self.scLabel.text = [NSString stringWithFormat:@"%@, %@, %@", [scData formattedCadence:YES], [scData formattedSpeed:YES], [scData formattedDistance:YES]];
			NSLog(@"received SC data: %@", scData);
		}
	}
}

- (IBAction)hrSwitched:(UISwitch *)sender
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:[sender isOn] forKey:BTLE_HR_ENABLED];
	[userDefaults synchronize];
	//[self checkConnectionStates];
}

- (IBAction)scSwitched:(UISwitch *)sender
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:[sender isOn] forKey:BTLE_SC_ENABLED];
	[userDefaults synchronize];
	//[self checkConnectionStates];
}

@end
