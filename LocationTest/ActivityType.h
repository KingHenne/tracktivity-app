//
//  ActivityType.h
//  LocationTest
//
//  Created by Hendrik on 07.10.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Activity;

@interface ActivityType : NSManagedObject

@property (nonatomic, retain) NSString * stringValue;
@property (nonatomic, retain) NSString * emojiIcon;
@property (nonatomic, retain) NSNumber * displayOrder;
@property (nonatomic, retain) NSString * localizedLabel;
@property (nonatomic, retain) NSSet *activities;
@end

@interface ActivityType (CoreDataGeneratedAccessors)

- (void)addActivitiesObject:(Activity *)value;
- (void)removeActivitiesObject:(Activity *)value;
- (void)addActivities:(NSSet *)values;
- (void)removeActivities:(NSSet *)values;

@end
