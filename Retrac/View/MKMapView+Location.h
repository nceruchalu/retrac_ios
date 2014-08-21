//
//  MKMapView+Location.h
//  Retrac
//
//  Created by Nnoduka Eruchalu on 8/4/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <MapKit/MapKit.h>

/**
 * This category on MKMapView provides utility functions this app needs such
 * as zooming in on annotations.
 */
@interface MKMapView (Location)

#pragma mark - Instance Methods
/**
 * Sets the visible region so that the map displays the specified annotations.
 * This does a better job than `showAnnotations:animated:` which does cover all
 * annotations but has the camera too far out.
 */
- (void)zoomToAnnotations;

@end
