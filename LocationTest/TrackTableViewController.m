//
//  ActivityTableViewController.m
//  LocationTest
//
//  Created by Hendrik Liebau on 23.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import "TrackTableViewController.h"
#import "Track+Data.h"
#import "TrackHandler.h"
#import <MapKit/MapKit.h>
#import <QuartzCore/CALayer.h>
#import "GoogleStaticMapsFetcher.h"
#import "Activity.h"
#import "Route.h"
#import "AppDelegate.h"
#import <RestKit/RestKit.h>

@implementation TrackTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	[self performSelectorOnMainThread:@selector(setupFetchedResultsController) withObject:nil waitUntilDone:NO];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

- (void)setupFetchedResultsController
{
	// Implement this method in a conrete subclass.
	[self doesNotRecognizeSelector:_cmd];
}

- (void)deleteTracks
{
	[self.fetchedResultsController.fetchedObjects makeObjectsPerformSelector:@selector(deleteEntity)];
	[self saveContext];
}

- (void)deleteThumbnails
{
	[self.fetchedResultsController.fetchedObjects makeObjectsPerformSelector:@selector(setThumbnail:) withObject:nil];
	[self saveContext];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"Recorded Activity Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    Track *track = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	if ([track isKindOfClass:[Activity class]]) {
		Activity *activity = (Activity *) track;
		if (track.name) {
			cell.textLabel.text = track.name;
			cell.detailTextLabel.text = [NSDateFormatter localizedStringFromDate:activity.start dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
		} else {
			cell.textLabel.text = [NSDateFormatter localizedStringFromDate:activity.start dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
			cell.detailTextLabel.text = [NSDateFormatter localizedStringFromDate:activity.end dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
		}
	} else if ([track isKindOfClass:[Route class]]) {
		Route *route = (Route *) track;
		cell.textLabel.text = route.name;
		cell.detailTextLabel.text = [NSDateFormatter localizedStringFromDate:route.created dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
	}
	UIImage *thumbnail = track.thumbnail;
	// Fetch the image again, if this is a retina screen and the saved image was fetched on non-retina device.
	if (thumbnail == nil || ([[UIScreen mainScreen] scale] > 1 && thumbnail.size.width < 54)) {
		cell.imageView.image = [UIImage imageNamed:@"mapThumbnail.png"];
		NSManagedObjectID *trackObjectID = track.objectID;
		if (trackObjectID.isTemporaryID) { // try again later
			[self.tableView performSelector:@selector(reloadData)];
		} else {
			dispatch_queue_t queue = dispatch_queue_create("thumbnail fetch queue", NULL);;
			dispatch_async(queue, ^{
				NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
				Track *t = (Track *) [context objectWithID:trackObjectID];
				if (t) {
					NSDate *start = [NSDate date];
					NSString *encodedPolylineString = t.encodedPolylineString;
					NSTimeInterval time = [start timeIntervalSinceNow];
					NSLog(@"Encoded polyline string in %.0f milliseconds.", time * -1000);
					UIImage *thumbnail = [GoogleStaticMapsFetcher mapImageForEncodedPath:encodedPolylineString width:53 height:53 withLabels:NO];
					if (thumbnail) {
						t.thumbnail = thumbnail;
						[self saveContext];
					}
				}
			});
			dispatch_release(queue);
		}
	} else {
		cell.imageView.image = thumbnail;
	}
    
    return cell;
}

- (void)saveContext
{
	NSError *error;
	if (![RKManagedObjectStore.defaultObjectStore save:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		// Delete the managed object at the given index path.
		Track *track = [self.fetchedResultsController objectAtIndexPath:indexPath];
		// If the track is a synced activity, first delete it from the server.
		if ([track isKindOfClass:[Activity class]]) {
			Activity *activity = (Activity *) track;
			if (activity.tracktivityID) {
				[[RKObjectManager sharedManager] deleteObject:track delegate:self];
			}
		}
		[track deleteEntity];
		[self saveContext];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark RestKit Delegate Methods

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error
{
	NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
}

#pragma mark Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
	Track *track = [self.fetchedResultsController objectAtIndexPath:indexPath];
	if ([segue.destinationViewController conformsToProtocol:@protocol(TrackHandler)]) {
		UIViewController <TrackHandler> *trackHandler = (UIViewController <TrackHandler> *) segue.destinationViewController;
		trackHandler.track = track;
		if ([sender isKindOfClass:[UITableViewCell class]]) {
			UITableViewCell *cell = (UITableViewCell *) sender;
			trackHandler.title = cell.textLabel.text;
			//trackHandler.title = cell.detailTextLabel.text;
		}
	}
}

@end
