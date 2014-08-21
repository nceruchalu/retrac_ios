//
//  RTCPlaceDirectionsViewController.h
//  Retrac
//
//  Created by Nnoduka Eruchalu on 8/2/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RTCPlace;

/**
 * RTCLocationViewController provides the user with route directions to a 
 * specific place
 */
@interface RTCPlaceDirectionsViewController : UIViewController

/**
 * The start location is always the user's current location, so the associated
 * View Controller model is the destination.
 */
@property (strong, nonatomic) RTCPlace *destinationPlace;

@end
