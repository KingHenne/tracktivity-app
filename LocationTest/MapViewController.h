//
//  MapViewController.h
//  LocationTest
//
//  Created by Hendrik Liebau on 15.07.12.
//  Copyright (c) 2012 SinnerSchrader. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MKMapView.h>

@interface MapViewController : UIViewController <MKMapViewDelegate>

@property (nonatomic, weak) IBOutlet MKMapView *mapView;

@end
