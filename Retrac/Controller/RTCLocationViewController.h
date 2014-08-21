//
//  RTCLocationViewController.h
//  Retrac
//
//  Created by Nnoduka Eruchalu on 7/31/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "RTCScrollViewContainer.h"

@class CLLocation;
@class RTCPlace;

/**
 * RTCLocationViewController provides the user with a view of their current
 * location, the ability to associate a name with it and the ability to refresh
 * the current user location.
 * 
 * This class is best used when subclassed
 */
@interface RTCLocationViewController : RTCScrollViewContainer

#pragma mark - Properties
/**
 * The captured location
 */
@property (strong, nonatomic, readonly) CLLocation *location;

/**
 * internal handle to the database
 */
@property (strong, nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

#pragma mark - Class Methods
/**
 * Configure button to have a visible border with rounded corners. The border
 * color is the same color as the button currentTitleColor property
 *
 * @param button    button to be configured
 */
+ (void)addRoundedBorder:(UIButton *)button;


#pragma mark - Instance Methods
#pragma mark Abstract
/**
 * Enable the save button
 */
- (void)enableSaveButton; // abstract

/**
 * Disable save button and indicate if this is because of a successful save.
 */
- (void)disableSaveButton:(BOOL)saved; // abstract

#pragma mark Concrete
/**
 * Create place from values of elements in View Controller and save in CoreData
 *
 * This expects the managedObjectContext and location to be ready else it won't
 * create a place.
 *
 * @return the created RTCPlace
 */
- (RTCPlace *)createPlace;

@end
