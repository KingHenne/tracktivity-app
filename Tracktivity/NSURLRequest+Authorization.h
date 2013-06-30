//
//  NSURLRequest+Authorization.h
//  Tracktivity
//
//  Created by Hendrik on 29.06.13.
//  Copyright (c) 2013 SinnerSchrader. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLRequest (Authorization)

+ (NSURLRequest *) requestWithURLString:(NSString *)URLString username:(NSString *)username password:(NSString *)password;
+ (NSURLRequest *) requestWithURL:(NSURL *)url username:(NSString *)username password:(NSString *)password;

@end
