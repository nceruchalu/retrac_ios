//
//  RTCPlace+Location.h
//  Retrac
//
//  Created by Nnoduka Eruchalu on 8/1/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//
/**
 *  Using this file as to document the RTCPlace model which represents a saved
 *  user location
 *
 *  Property            Purpose
 *  creationDate        Date/Time when place was saved
 *  location            CLLocation associated with place (contains long./lat.)
 *  placemark           Reverse-geocoded CLPlacemark based on location
 *  name                Friendly name for this place.
 *  timeout (Unused)    Number of seconds till a return to this place is required
 */

#import "RTCPlace.h"

/**
 * The Location category covers the following Location Services and Maps functions:
 * - Creation of instance
 * - Representation in the Location View Controllers
 */
@interface RTCPlace (Location)

#pragma mark - Class Methods

/**
 * Create full address string given a placemark
 *
 * @param placemark     Placemark object to be converted to address string
 */
+ (NSString *)addressFromPlacemark:(CLPlacemark *)placemark;

/**
 * Generate a truncated name from a given full name
 *
 * @param name  original name to be truncated
 */
+ (NSString *)truncatedName:(NSString *)name;

/**
 * Generate a time-label for a time such as time since created or time to expiry
 *
 * @param placeTime     time interval to be converted to a label
 *
 * @return time interval string with the following format:
 *      - xxd when time interval is >= 1 day
 *      - xxh when time interval is < 1 day and >= 1 hour
 *      - xxm when time interval is < 1 hour and >= 0 minutes
 *      - nil if time interval < 0
 */
+ (NSString *)timeLabelForPlaceDate:(NSTimeInterval)placeTime;

/**
 * Create place with provided attributes.
 *
 * @param name          place's friendly name
 * @param location      location to be associated with place.
 * @param placemark     location's reverse-geocoded placemark
 * @param context       handle to database
 *
 * @return Initialized RTCPlace instance
 */
+ (instancetype)placeWithName:(NSString *)name
                     location:(CLLocation *)location
                    placemark:(CLPlacemark *)placemark
       inManagedObjectContext:(NSManagedObjectContext *)context;


#pragma mark - Instance Methods

/**
 * String representation of time since creation of Place
 */
- (NSString *)timeSinceCreation;

@end
