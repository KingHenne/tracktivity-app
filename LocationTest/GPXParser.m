//
//  GPXParser.m
//  LocationTest
//
//  Created by Hendrik on 04.08.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "GPXParser.h"
#import "Track+Create.h"
#import "Activity+Create.h"
#import "Route.h"
#import "Segment+Create.h"
#import "Waypoint+Create.h"
#import "RestKit/ISO8601DateFormatter.h"
#import "NSURL+FileHelper.h"
#import <RestKit/RestKit.h>
#import <TBXML-Headers/TBXML.h>

@interface GPXParser ()
@property NSMutableDictionary *elementStates;
@property Route *currentTrack;
@property Segment *currentSegment;
@property Waypoint *currentTrackPoint;
@property Waypoint *currentWayPoint;
@property NSURL *fileURL;
@property int pointsParsed;
@property int totalPointsToParse;
@property (nonatomic) float parseProgress;
@end

@implementation GPXParser

@synthesize parsedTrack = _parsedTrack;
@synthesize elementStates = _elementStates;
@synthesize currentTrack = _currentTrack;
@synthesize currentSegment = _currentSegment;
@synthesize currentTrackPoint = _currentTrackPoint;
@synthesize currentWayPoint = _currentWayPoint;
@synthesize fileURL = _fileURL;
@synthesize pointsParsed = _pointsParsed;
@synthesize totalPointsToParse = _totalPointsToParse;
@synthesize parseProgress = _parseProgress;

- (void)setParseProgress:(float)parseProgress
{
	if (parseProgress >= 0 && parseProgress <= 1) {
		_parseProgress = parseProgress;
	}
}

- (BOOL)parseGPXFile:(NSURL *)fileURL
{
	self.fileURL = fileURL;
	NSString *xmlFileString = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:NULL];
	self.pointsParsed = 0;
	self.totalPointsToParse	= [xmlFileString componentsSeparatedByString:@"<trkpt"].count - 1;
	NSLog(@"totalPointsToParse=%d", self.totalPointsToParse);
	NSError *error;
	NSDate *start = [NSDate date];
	TBXML *tbxml = [TBXML newTBXMLWithXMLString:xmlFileString error:&error];
	if (error) {
        NSLog(@"%@ %@", [error localizedDescription], [error userInfo]);
		return NO;
    }
	// If TBXML found a root node, process element and iterate all children
	if (tbxml.rootXMLElement) {
		[self traverseElement:tbxml.rootXMLElement];
	}
	NSTimeInterval time = [start timeIntervalSinceNow];
	NSLog(@"Finished parsing %d points in %.2f seconds.", self.pointsParsed, time * -1);
    return YES;
}

- (void) traverseElement:(TBXMLElement *)element
{
	do {
		[self didStartElement:element];
		
		// Extract the content of the current element.
		[self didFindContent:[TBXML textForElement:element]];
		
		// If the element has child elements, process them.
		if (element->firstChild) {
			[self traverseElement:element->firstChild];
		}
		
		[self didEndElement:element];
		
		// Obtain next sibling element.
	} while ((element = element->nextSibling));
}

- (void)didStartElement:(TBXMLElement *)element
{
	NSString *elementName = [TBXML elementName:element].lowercaseString;
	[self.elementStates setObject:[NSNumber numberWithBool:YES] forKey:elementName];
	if ([elementName isEqualToString:@"trk"]) {
		self.currentTrack = [Route createEntity];
		self.currentTrack.created = [NSDate date];
	} else if ([elementName isEqualToString:@"trkseg"]) {
		self.currentSegment = [Segment createEntity];
	} else if ([elementName isEqualToString:@"trkpt"]) {
		double lat = [[TBXML valueOfAttributeNamed:@"lat" forElement:element] doubleValue];
		double lon = [[TBXML valueOfAttributeNamed:@"lon" forElement:element] doubleValue];
		self.currentTrackPoint = [Waypoint createEntity];
		self.currentTrackPoint.latitude = [NSNumber numberWithDouble:lat];
		self.currentTrackPoint.longitude = [NSNumber numberWithDouble:lon];
	}
}

- (void)didFindContent:(NSString *)string
{
	if ([[self.elementStates objectForKey:@"trk"] boolValue] == YES) {
		if ([[self.elementStates objectForKey:@"name"] boolValue] == YES) {
			self.currentTrack.name = string;
		}
		if ([[self.elementStates objectForKey:@"desc"] boolValue] == YES) {
			self.currentTrack.desc = string;
		}
		if ([[self.elementStates objectForKey:@"trkseg"] boolValue] == YES &&
			[[self.elementStates objectForKey:@"trkpt"] boolValue] == YES) {
			if ([[self.elementStates objectForKey:@"ele"] boolValue] == YES) {
				self.currentTrackPoint.elevation = [NSNumber numberWithDouble:[string doubleValue]];
			}
			if ([[self.elementStates objectForKey:@"time"] boolValue] == YES) {
				ISO8601DateFormatter *formatter = [[ISO8601DateFormatter alloc] init];
				self.currentTrackPoint.time = [formatter dateFromString:string];
			}
		}
	}
}

- (void)didEndElement:(TBXMLElement *)element
{
	NSString *elementName = [TBXML elementName:element].lowercaseString;
	[self.elementStates setObject:[NSNumber numberWithBool:NO] forKey:elementName];
	if ([elementName isEqualToString:@"trk"]) {
		if (self.currentTrack.name == nil) {
			self.currentTrack.name = self.fileURL.fileNameWithoutExtension;
		}
		self.currentTrack.originalFile = [NSData dataWithContentsOfURL:self.fileURL];
		[self saveContext];
		self.parsedTrack = self.currentTrack;
		self.currentTrack = nil;
	} else if ([elementName isEqualToString:@"trkseg"]) {
		[self.currentTrack addSegmentsObject:self.currentSegment];
		self.currentSegment = nil;
	} else if ([elementName isEqualToString:@"trkpt"]) {
		[self.currentSegment addPointsObject:self.currentTrackPoint];
		self.currentTrackPoint = nil;
		self.pointsParsed++;
		self.parseProgress = (float)self.pointsParsed / (float)self.totalPointsToParse;
	}
}

- (void)saveContext
{
    NSError *error = nil;
	if (![RKManagedObjectStore.defaultObjectStore save:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
}

@end
