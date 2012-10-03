//
//  FinishActivityViewController.h
//  LocationTest
//
//  Created by Hendrik on 01.10.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Activity.h"
#import "WrappedTrackHandler.h"

@interface FinishActivityViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, WrappedTrackHandler>

@property (nonatomic, strong) Activity *activity;

@end
