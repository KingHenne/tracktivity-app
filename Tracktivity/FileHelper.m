//
//  FileHelper.m
//  Tracktivity
//
//  Created by Hendrik on 03.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "FileHelper.h"
#import "NSURL+FileHelper.h"

@implementation FileHelper

+ (NSURL *)createUniqueFileURLFromURL:(NSURL *)url
{
	NSFileManager *manager = [NSFileManager defaultManager];
	
	int index = 1;
	while ([manager fileExistsAtPath:[url path]]) {
		NSString *newFileName = [NSString stringWithFormat:@"%@-%d.%@", url.fileNameWithoutExtension, index, url.pathExtension];
		url = [[url URLByDeletingLastPathComponent] URLByAppendingPathComponent:newFileName];
		index++;
	}
	
	return url;
}

+ (NSURL *)importDirectory
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSURL *userDocDir = [[manager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
	NSURL *importDir = [userDocDir URLByAppendingPathComponent:@"import" isDirectory:YES];
	BOOL isDir;
	if (![manager fileExistsAtPath:[importDir path] isDirectory:&isDir]) {
		NSError *fileManagerError;
		if (![manager createDirectoryAtURL:importDir withIntermediateDirectories:YES attributes:nil error:&fileManagerError]) {
			NSLog(@"An error occured trying to create a directory: %@", fileManagerError);
			return nil;
		}
	} else if (!isDir) {
		NSLog(@"The import directory already exists as a file.");
		return nil;
	}
	return importDir;
}

@end
