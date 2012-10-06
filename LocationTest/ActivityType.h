//
//  ActivityType.h
//  LocationTest
//
//  Created by Hendrik on 06.10.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ActivityType : NSObject

typedef enum {
	CYCLING = 0,
	HIKING  = 1,
	RUNNING = 2,
	INLINE  = 3
} ActivityTypeCode;

+ (ActivityTypeCode)codeForStringValue:(NSString *)value;
+ (NSString *)stringValueForActivity:(ActivityTypeCode)code;
+ (NSString *)localizedLabelForActivity:(ActivityTypeCode)code;
+ (NSString *)emojiIconForActivity:(ActivityTypeCode)code;
+ (NSDictionary *)localizedLabels;

@end
