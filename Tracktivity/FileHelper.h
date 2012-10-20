//
//  FileHelper.h
//  Tracktivity
//
//  Created by Hendrik on 03.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileHelper : NSObject

+ (NSURL *)createUniqueFileURLFromURL:(NSURL *)url;
+ (NSURL *)importDirectory;

@end
