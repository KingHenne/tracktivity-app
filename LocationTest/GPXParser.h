//
//  GPXParser.h
//  LocationTest
//
//  Created by Hendrik on 04.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Track.h"

@interface GPXParser : NSObject <NSXMLParserDelegate>

@property (nonatomic, strong) Track *parsedTrack;
@property (nonatomic, readonly) float parseProgress;

- (BOOL)parseGPXFile:(NSURL *)fileURL;

@end
