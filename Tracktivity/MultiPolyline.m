//
//  MultiPolyline.m
//  Tracktivity
//
//  Created by Hendrik on 23.09.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "MultiPolyline.h"

@interface MultiPolyline ()
@property (nonatomic, strong) NSMutableArray *array;
@end

@implementation MultiPolyline

@synthesize array = _array;

- (NSMutableArray *)array
{
	if (_array == nil) {
		_array = [NSMutableArray new];
	}
	return _array;
}

- (NSArray *)polylines
{
	return self.array.copy;
}

- (void)addPolyline:(MKPolyline *)polyline
{
	[self.array addObject:polyline];
}

@end
