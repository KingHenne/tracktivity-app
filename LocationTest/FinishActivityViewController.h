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

@class FinishActivityViewController;

@protocol FinishActivityViewControllerPresenter <NSObject>

- (void)finishActivityViewController:(FinishActivityViewController *)sender
				   didFinishActivity:(Activity *)activity;

@end

@interface FinishActivityViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, WrappedTrackHandler>

@property (nonatomic, strong) Activity *activity;
@property (nonatomic, weak) id <FinishActivityViewControllerPresenter> delegate;

@end
