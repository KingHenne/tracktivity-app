//
//  AppDelegate.h
//  LocationTest
//
//  Created by Hendrik Liebau on 14.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RestKit/RestKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate, RKManagedObjectStoreDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
