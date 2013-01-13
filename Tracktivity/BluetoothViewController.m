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
	
	if (hardwareConnector.isCommunicationHWReady) {
		// set up existing or new sensor connections
		[self requestHrConnection];
		[self requestScConnection];
        // update the view
		[self checkConnectionStates];
        [self updateData];
    }
    
    // register for HW connector notifications.
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sensorConnected) name:WF_NOTIFICATION_SENSOR_CONNECTED object:nil];
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sensorDisconnected) name:WF_NOTIFICATION_SENSOR_DISCONNECTED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateData) name:WF_NOTIFICATION_SENSOR_HAS_DATA object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)sensorConnected
{
	[self checkConnectionStates];
}

- (void)sensorDisconnected
{
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

- (void)requestHrConnection
{
	WFHardwareConnector *hardwareConnector = [WFHardwareConnector sharedConnector];
	NSArray* connections = [hardwareConnector getSensorConnections:WF_SENSORTYPE_HEARTRATE];
	self.hrConnection = ([connections count]>0) ? (WFHeartrateConnection *)[connections objectAtIndex:0] : nil;
	if (self.hrConnection == nil) {
		WFConnectionParams *params = [hardwareConnector.settings connectionParamsForSensorType:WF_SENSORTYPE_HEARTRATE];
		//params.searchTimeout = hardwareConnector.settings.discoveryTimeout;
		self.hrConnection = (WFHeartrateConnection *)[hardwareConnector requestSensorConnection:params];
	}
	self.hrConnection.delegate = self;
}

- (void)requestScConnection
{
	WFHardwareConnector *hardwareConnector = [WFHardwareConnector sharedConnector];
	NSArray* connections = [hardwareConnector getSensorConnections:WF_SENSORTYPE_BIKE_SPEED_CADENCE];
	self.scConnection = ([connections count]>0) ? (WFBikeSpeedCadenceConnection *)[connections objectAtIndex:0] : nil;
	if (self.scConnection == nil) {
		WFConnectionParams *params = [hardwareConnector.settings connectionParamsForSensorType:WF_SENSORTYPE_BIKE_SPEED_CADENCE];
		//params.searchTimeout = hardwareConnector.settings.discoveryTimeout;
		self.scConnection = (WFBikeSpeedCadenceConnection *)[hardwareConnector requestSensorConnection:params];
	}
	self.scConnection.delegate = self;
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
	if ([sender isOn]) {
		[self requestHrConnection];
	} else {
		[self.hrConnection disconnect];
	}
	[self checkConnectionStates];
}

- (IBAction)scSwitched:(UISwitch *)sender
{
	if ([sender isOn]) {
		[self requestScConnection];
	} else {
		[self.scConnection disconnect];
	}
	[self checkConnectionStates];
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
	[self checkConnectionStates];
}

- (void)connection:(WFSensorConnection*)connectionInfo stateChanged:(WFSensorConnectionStatus_t)connState
{
	NSLog(@"SENSOR CONNECTION STATE CHANGED: connState = %d (IDLE=%d)", connState, WF_SENSOR_CONNECTION_STATUS_IDLE);
    
    // check for a valid connection.
    if (connectionInfo.isValid && connectionInfo.isConnected)
    {
        // process post-connection setup.
		[[WFHardwareConnector sharedConnector].settings saveConnectionInfo:connectionInfo];
		
        // update the display.
        [self updateData];
    }
	
	[self checkConnectionStates];
}

@end
