//
//  ImportViewController.m
//  Tracktivity
//
//  Created by Hendrik on 12.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "ImportViewController.h"

@interface ImportViewController ()
@property (weak, nonatomic) IBOutlet UILabel *fileNameLabel;
@end

@implementation ImportViewController
@synthesize fileNameLabel = _fileNameLabel;
@synthesize progressBar = _progressBar;
@synthesize fileName = _fileName;

- (void)setFileName:(NSString *)fileName
{
	_fileName = fileName;
	self.fileNameLabel.text = fileName;
}

- (void)setFileNameLabel:(UILabel *)fileNameLabel
{
	_fileNameLabel = fileNameLabel;
	_fileNameLabel.text = self.fileName;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
	[self setFileNameLabel:nil];
	[self setProgressBar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
