//
//  OpenInSafariActivity.m
//  Tracktivity
//
//  Created by Hendrik on 21.10.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "OpenInSafariActivity.h"

@interface OpenInSafariActivity ()
@property (nonatomic, strong) NSURL *url;
@end

@implementation OpenInSafariActivity

@synthesize url = _url;

- (NSString *)activityType
{
	return @"OpenInSafariActivity";
}

- (NSString *)activityTitle
{
	return @"Safari";
}

- (UIImage *)activityImage
{
	if (IPAD) {
		return [UIImage imageNamed:@"activitySafari-55.png"];
	}
	return [UIImage imageNamed:@"activitySafari-43.png"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
	for (id item in activityItems) {
		if ([item isKindOfClass:[NSURL class]]) {
			return YES;
		}
	}
	return NO;
}

// saves the first occurence of an NSURL item
- (void)prepareWithActivityItems:(NSArray *)activityItems
{
	for (id item in activityItems) {
		if ([item isKindOfClass:[NSURL class]]) {
			self.url = item;
			return;
		}
	}
}

- (void)performActivity
{
	BOOL success = NO;
	if (self.url) {
		success = [[UIApplication sharedApplication] openURL:self.url];
	}
	[self activityDidFinish:success];
}

@end
