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
#import "ISO8601DateFormatter.h"
#import "NSURL+FileHelper.h"

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

@synthesize context = _context;
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

- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
	self = [super init];
	if (self) {
		self.context = [[NSManagedObjectContext alloc] init];
		self.context.persistentStoreCoordinator = persistentStoreCoordinator;
	}
	return self;
}

- (void)setParseProgress:(float)parseProgress
{
	if (parseProgress >= 0 && parseProgress <= 1) {
		_parseProgress = parseProgress;
	}
}

- (BOOL)parseGPXFile:(NSURL *)fileURL
{
	NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:fileURL];
	self.fileURL = fileURL;
	NSString *xmlFileString = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:NULL];
	self.pointsParsed = 0;
	self.totalPointsToParse	= [xmlFileString componentsSeparatedByString:@"<trkpt"].count - 1;
	NSLog(@"totalPointsToParse=%d", self.totalPointsToParse);
	xmlParser.delegate = self;
	return [xmlParser parse];
}

- (void)saveContext
{
    NSError *error = nil;
	if ([self.context hasChanges] && ![self.context save:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
}

#pragma mark NSXMLParserDelegate Methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
	attributes:(NSDictionary *)attributeDict
{
	[self.elementStates setObject:[NSNumber numberWithBool:YES] forKey:elementName.lowercaseString];
	if ([elementName.lowercaseString isEqualToString:@"trk"]) {
		self.currentTrack = [NSEntityDescription insertNewObjectForEntityForName:@"Route"
														  inManagedObjectContext:self.context];
		self.currentTrack.created = [NSDate date];
	} else if ([elementName.lowercaseString isEqualToString:@"trkseg"]) {
		self.currentSegment = [NSEntityDescription insertNewObjectForEntityForName:@"Segment"
														 inManagedObjectContext:self.context];
	} else if ([elementName.lowercaseString isEqualToString:@"trkpt"]) {
		double lat = [[attributeDict objectForKey:@"lat"] doubleValue];
		double lon = [[attributeDict objectForKey:@"lon"] doubleValue];
		self.currentTrackPoint = [NSEntityDescription insertNewObjectForEntityForName:@"Waypoint"
														inManagedObjectContext:self.context];
		self.currentTrackPoint.latitude = [NSNumber numberWithDouble:lat];
		self.currentTrackPoint.longitude = [NSNumber numberWithDouble:lon];
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
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
				/*if (self.currentTrack.segments.count == 0 && self.currentSegment.points.count == 0) {
					self.currentTrack.start = self.currentTrackPoint.time;
				}*/
			}
		}
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
{	
	[self.elementStates setObject:[NSNumber numberWithBool:NO] forKey:elementName.lowercaseString];
	if ([elementName.lowercaseString isEqualToString:@"trk"]) {
		//self.currentTrack.end = self.currentTrackPoint.time;
		if (self.currentTrack.name == nil) {
			self.currentTrack.name = self.fileURL.fileNameWithoutExtension;
		}
		self.currentTrack.originalFile = [NSData dataWithContentsOfURL:self.fileURL];
		[self saveContext];
		self.parsedTrack = self.currentTrack;
		self.currentTrack = nil;
	} else if ([elementName.lowercaseString isEqualToString:@"trkseg"]) {
		[self.currentTrack addSegmentsObject:self.currentSegment];
		self.currentSegment = nil;
	} else if ([elementName.lowercaseString isEqualToString:@"trkpt"]) {
		[self.currentSegment addPointsObject:self.currentTrackPoint];
		self.currentTrackPoint = nil;
		self.pointsParsed++;
		self.parseProgress = (float)self.pointsParsed / (float)self.totalPointsToParse;
	}
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
	NSLog(@"Finished parsing %d points.", self.pointsParsed);
}

@end
