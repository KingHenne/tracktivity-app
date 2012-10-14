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
@property (nonatomic, strong) NSMutableDictionary *elementStates;
@property (nonatomic, strong) Route *currentRoute;
@property (nonatomic, strong) Segment *currentSegment;
@property (nonatomic, strong) Waypoint *currentRoutePoint;
@property (nonatomic, strong) Waypoint *currentWayPoint;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic) int pointsParsed;
@property (nonatomic) int totalPointsToParse;
@property (nonatomic) float parseProgress;
@end

@implementation GPXParser

@synthesize parsedRoute = _parsedRoute;
@synthesize elementStates = _elementStates;
@synthesize currentRoute = _currentRoute;
@synthesize currentSegment = _currentSegment;
@synthesize currentRoutePoint = _currentRoutePoint;
@synthesize currentWayPoint = _currentWayPoint;
@synthesize fileURL = _fileURL;
@synthesize pointsParsed = _pointsParsed;
@synthesize totalPointsToParse = _totalPointsToParse;
@synthesize parseProgress = _parseProgress;

- (NSMutableDictionary *)elementStates
{
	if (_elementStates == nil) {
		_elementStates = [NSMutableDictionary new];
	}
	return _elementStates;
}

- (void)setParseProgress:(float)parseProgress
{
	if (parseProgress >= 0 && parseProgress <= 1) {
		_parseProgress = parseProgress;
	}
}

- (BOOL)parseGPXFile:(NSURL *)fileURL
{
	self.fileURL = fileURL;
	NSString *xmlFileString;
	if ([fileURL.scheme isEqualToString:@"tracktivity"]) {
		fileURL = [NSURL URLWithString:[fileURL.absoluteString stringByReplacingOccurrencesOfString:@"tracktivity://" withString:@"http://"]];
	}
	
	NSError *error;
	xmlFileString = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
	if (error) {
		NSLog(@"%@ is not a valid URL to import GPX files from.", fileURL);
		return NO;
	}
	
	self.pointsParsed = 0;
	self.totalPointsToParse	= [xmlFileString componentsSeparatedByString:@"<trkpt"].count - 1;
	if (!self.totalPointsToParse) {
		self.totalPointsToParse	= [xmlFileString componentsSeparatedByString:@"<rtept"].count - 1;
	}
	if (!self.totalPointsToParse) {
		NSLog(@"There are no trkpt elements in this GPX file.");
		return NO;
	}
	NSLog(@"totalPointsToParse=%d", self.totalPointsToParse);
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
	if ([elementName isEqualToString:@"trk"] || [elementName isEqualToString:@"rte"]) {
		self.currentRoute = [Route createEntity];
		self.currentRoute.created = [NSDate date];
		self.currentRoute.track = [Track createEntity];
		if ([elementName isEqualToString:@"rte"]) {
			self.currentSegment = [Segment createEntity];
		}
	} else if ([elementName isEqualToString:@"trkseg"]) {
		self.currentSegment = [Segment createEntity];
	} else if ([elementName isEqualToString:@"trkpt"] || [elementName isEqualToString:@"rtept"]) {
		double lat = [[TBXML valueOfAttributeNamed:@"lat" forElement:element] doubleValue];
		double lon = [[TBXML valueOfAttributeNamed:@"lon" forElement:element] doubleValue];
		self.currentRoutePoint = [Waypoint createEntity];
		self.currentRoutePoint.latitude = [NSNumber numberWithDouble:lat];
		self.currentRoutePoint.longitude = [NSNumber numberWithDouble:lon];
	}
}

- (void)didFindContent:(NSString *)string
{
	if ([[self.elementStates objectForKey:@"trk"] boolValue] == YES ||
		[[self.elementStates objectForKey:@"rte"] boolValue] == YES) {
		if ([[self.elementStates objectForKey:@"trkpt"] boolValue] == NO &&
			[[self.elementStates objectForKey:@"rtept"] boolValue] == NO &&
			[[self.elementStates objectForKey:@"name"] boolValue] == YES) {
			self.currentRoute.name = string;
		}
		if ([[self.elementStates objectForKey:@"desc"] boolValue] == YES) {
		}
		if ([[self.elementStates objectForKey:@"trkpt"] boolValue] == YES ||
			[[self.elementStates objectForKey:@"rtept"] boolValue] == YES) {
			if ([[self.elementStates objectForKey:@"ele"] boolValue] == YES) {
				self.currentRoutePoint.elevation = [NSNumber numberWithDouble:[string doubleValue]];
			}
			if ([[self.elementStates objectForKey:@"time"] boolValue] == YES) {
				//ISO8601DateFormatter *formatter = [[ISO8601DateFormatter alloc] init];
				//self.currentRoutePoint.time = [formatter dateFromString:string];
			}
		}
	}
}

- (void)didEndElement:(TBXMLElement *)element
{
	NSString *elementName = [TBXML elementName:element].lowercaseString;
	[self.elementStates setObject:[NSNumber numberWithBool:NO] forKey:elementName];
	if ([elementName isEqualToString:@"trk"] || [elementName isEqualToString:@"rte"]) {
		if (self.currentRoute.name == nil) {
			self.currentRoute.name = self.fileURL.fileNameWithoutExtension;
		}
		self.currentRoute.originalFile = [NSData dataWithContentsOfURL:self.fileURL];
		if ([elementName isEqualToString:@"rte"]) {
			[self.currentRoute.track addSegmentsObject:self.currentSegment];
			self.currentSegment = nil;
		}
		[self saveContext];
		self.parsedRoute = self.currentRoute;
		self.currentRoute = nil;
	} else if ([elementName isEqualToString:@"trkseg"]) {
		[self.currentRoute.track addSegmentsObject:self.currentSegment];
		self.currentSegment = nil;
	} else if ([elementName isEqualToString:@"trkpt"] || [elementName isEqualToString:@"rtept"]) {
		[self.currentSegment addPointsObject:self.currentRoutePoint];
		self.currentRoutePoint = nil;
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
