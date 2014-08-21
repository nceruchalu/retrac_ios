//
//  RTCAddPlaceViewController.h
//  Retrac
//
//  Created by Nnoduka Eruchalu on 8/1/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "RTCLocationViewController.h"

/**
 * RTCAddPlaceViewController is a subclass of RTCLocationViewController which is
 * presented modally for adding a place
 */
@interface RTCAddPlaceViewController : RTCLocationViewController

/**
 * The created place. This will be the output of the VC
 */
@property (strong, nonatomic, readonly) RTCPlace *createdPlace;

@end
