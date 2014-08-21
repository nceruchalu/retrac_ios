//
//  RTCPlace+MKAnnotation.h
//  Retrac
//
//  Created by Nnoduka Eruchalu on 8/2/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "RTCPlace.h"
#import <MapKit/MapKit.h>

/**
 * The MKAnnotation category is used to make the Place managedObject comply to
 * the MapKit's MKAnnotation protocol.
 */
@interface RTCPlace (MKAnnotation) <MKAnnotation>

@end
