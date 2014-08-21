//
//  RTCPlaceDetailsViewController.h
//  Retrac
//
//  Created by Nnoduka Eruchalu on 8/2/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RTCPlace;

/**
 * RTCPlaceDetailsViewController provides the user the details on a place
 * which is simply name and address.
 */
@interface RTCPlaceDetailsViewController : UIViewController

/**
 * The place of interest is the View Controller model.
 */
@property (strong, nonatomic) RTCPlace *place;

@end
