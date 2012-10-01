//
//  FinishActivityViewController.h
//  LocationTest
//
//  Created by Hendrik on 01.10.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Activity.h"
#import "TrackHandler.h"

@interface FinishActivityViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, TrackHandler>

@property (nonatomic, strong) Activity *activity;

@end
