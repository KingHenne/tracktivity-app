//
//  NSURLRequest+Authorization.m
//  Tracktivity
//
//  Created by Hendrik on 29.06.13.
//  Copyright (c) 2013 SinnerSchrader. All rights reserved.
//

#import "NSURLRequest+Authorization.h"

@implementation NSURLRequest (Authorization)

+ (NSURLRequest *) requestWithURLString:(NSString *)URLString username:(NSString *)username password:(NSString *)password
{
	NSURL *url = [NSURL URLWithString:URLString];
	return [NSURLRequest requestWithURL:url username:username password:password];
}

+ (NSURLRequest *) requestWithURL:(NSURL *)url username:(NSString *)username password:(NSString *)password
{
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
	NSString *authStr = [NSString stringWithFormat:@"%@:%@", username, password];
	NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
	NSString *encodedAuthStr = [authData base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];
	NSString *authValue = [NSString stringWithFormat:@"Basic %@", encodedAuthStr];
	[urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
	return urlRequest;
}

@end
