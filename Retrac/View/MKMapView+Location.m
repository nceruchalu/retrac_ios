//
//  MKMapView+Location.m
//  Retrac
//
//  Created by Nnoduka Eruchalu on 8/4/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "MKMapView+Location.h"


// Constants
// Choose what percentage of the width/height the mapview padding will be
static const CLLocationDegrees kMapViewPaddingWidth    = 1.1;
static const CLLocationDegrees kMapViewPaddingHeight   = 1.5; // maybe use 1.1 here

@implementation MKMapView (Location)

- (void)zoomToAnnotations
{
    // [self showAnnotations:self.annotations animated:YES];
    
    if([self.annotations count] == 0)
        return;
    
    CLLocationCoordinate2D topLeftCoord;
    topLeftCoord.latitude = -90;
    topLeftCoord.longitude = 180;
    
    CLLocationCoordinate2D bottomRightCoord;
    bottomRightCoord.latitude = 90;
    bottomRightCoord.longitude = -180;
    
    for (id <MKAnnotation> annotation in self.annotations) {
        topLeftCoord.longitude = fmin(topLeftCoord.longitude, annotation.coordinate.longitude);
        topLeftCoord.latitude = fmax(topLeftCoord.latitude, annotation.coordinate.latitude);
        
        bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, annotation.coordinate.longitude);
        bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, annotation.coordinate.latitude);
    }
    
    MKCoordinateRegion region;
    region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5;
    region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5;
    region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * kMapViewPaddingHeight; // Add a little extra space on the sides
    region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * kMapViewPaddingWidth; // Add a little extra space on the sides
    
    region = [self regionThatFits:region];
    [self setRegion:region animated:YES];
}

@end
