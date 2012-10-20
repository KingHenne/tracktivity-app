//
//  TabBarController.m
//  Tracktivity
//
//  Created by Hendrik on 12.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "TabBarController.h"
#import "ImportViewController.h"
#import "NSURL+FileHelper.h"

@interface TabBarController ()
@property (nonatomic, strong) ImportViewController *ivc;
@end

@implementation TabBarController

@synthesize ivc = _ivc;

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"Show Import View"] && [sender isKindOfClass:[NSURL class]]) {
		NSURL *url = (NSURL *) sender;
		self.ivc = (ImportViewController *) segue.destinationViewController;
		self.ivc.fileName = url.fileNameWithoutExtension;
	}
}

- (void)updateProgressBar:(NSNumber *)progress
{
	if (progress.floatValue > self.ivc.progressBar.progress) {
		[self.ivc.progressBar setProgress:progress.floatValue animated:YES];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"parseProgress"]) {
		NSNumber *progress = (NSNumber *) [change objectForKey:NSKeyValueChangeNewKey];
		[self performSelectorOnMainThread:@selector(updateProgressBar:) withObject:progress waitUntilDone:NO];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
