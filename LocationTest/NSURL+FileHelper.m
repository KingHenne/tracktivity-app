//
//  NSURL+FileHelper.m
//  LocationTest
//
//  Created by Hendrik on 05.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "NSURL+FileHelper.h"

@implementation NSURL (FileHelper)

- (NSString *)fileNameWithoutExtension
{
	NSString *fileExtension = [self pathExtension];
	NSString *fileNameWithExtension = [self lastPathComponent];
	return [fileNameWithExtension substringToIndex:fileNameWithExtension.length-fileExtension.length-1];
}

@end
