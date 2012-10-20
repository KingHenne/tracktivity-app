//
//  ImportViewController.h
//  Tracktivity
//
//  Created by Hendrik on 12.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImportViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (nonatomic, strong) NSString *fileName;

@end
