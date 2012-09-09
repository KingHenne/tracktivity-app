//
//  GoogleStaticMapsFetcher.h
//  LocationTest
//
//  Created by Hendrik on 01.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GoogleStaticMapsFetcher : NSObject

+ (id)mapImageForEncodedPath:(NSString *)encodedPath
					   width:(int)width
					  height:(int)height
				  withLabels:(BOOL)labels;

@end
