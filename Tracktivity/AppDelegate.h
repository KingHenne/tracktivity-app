//
//  AppDelegate.h
//  Tracktivity
//
//  Created by Hendrik Liebau on 14.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RestKit/RestKit.h>
#import <WFConnector/WFConnector.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate, RKManagedObjectStoreDelegate, WFHardwareConnectorDelegate>
{
	WFHardwareConnector* hardwareConnector;
}

@property (strong, nonatomic) UIWindow *window;

@end
