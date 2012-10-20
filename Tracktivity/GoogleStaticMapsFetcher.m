//
//  GoogleStaticMapsFetcher.m
//  Tracktivity
//
//  Created by Hendrik on 01.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "GoogleStaticMapsFetcher.h"

#define API_KEY @"AIzaSyCN2cDoZ48VOzB7as_UYZMk3rqO-XXlOqQ"
#define PATH_WIDTH 3
#define PATH_COLOR @"0x0073E6ee"

@implementation GoogleStaticMapsFetcher

+ (NSData *)executeFetch:(NSString *)query
{
    query = [NSString stringWithFormat:@"%@&key=%@", query, API_KEY];
	//NSLog(@"fetching data from URL: %@", query);
    query = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	return [NSData dataWithContentsOfURL:[NSURL URLWithString:query]];
}

+ (UIImage *)mapImageForEncodedPaths:(NSArray *)encodedPaths width:(int)width height:(int)height withLabels:(BOOL)labels
{
	int screenScale = (int) [[UIScreen mainScreen] scale];
    NSString *request = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/staticmap?size=%dx%d&scale=%d&sensor=false", width, height, screenScale];
	NSString *pathFormat = @"&path=color:%@|weight:%d|enc:%@";
	for (NSString *encodedPath in encodedPaths) {
		NSString *pathParams = [NSString stringWithFormat:pathFormat, PATH_COLOR, PATH_WIDTH, encodedPath];
		request = [request stringByAppendingString:pathParams];
	}
	if (!labels) {
		request = [request stringByAppendingString:@"&style=feature:all|element:labels|visibility:off"];
	}
    return [UIImage imageWithData:[self executeFetch:request]];
}

+ (UIImage *)mapImageForEncodedPath:(NSString *)encodedPath width:(int)width height:(int)height withLabels:(BOOL)labels
{
	return [self mapImageForEncodedPaths:[NSArray arrayWithObject:encodedPath] width:width height:height withLabels:labels];
}

@end
