//
//  RTCConstants.h
//  Retrac
//
//  Created by Nnoduka Eruchalu on 7/31/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//
//  Place file in precompiled header for the project

#import <CoreLocation/CoreLocation.h>

// Colors
/**
 * Theme Color is RGB #FF3B30
 */
#define kRTCThemeColor [UIColor colorWithRed:255.0/255.0 green:59.0/255.0 blue:48.0/255.0 alpha:1.0]

/**
 * Location blue color is RGB #3795D2
 */
#define kRTCLocationColor [UIColor colorWithRed:55.0/255.0 green:149.0/255.0 blue:210.0/255.0 alpha:1.0]

// Styling constants
/**
 * kRTCInputBorderThickness is the height/width of input borders
 */
extern const CGFloat kRTCInputBorderThickness;

/**
 * kRTCInputBorderRadius is the radius of input borders
 */
extern const CGFloat kRTCInputBorderRadius;


// Default font name
/**
 * kRTCFontName is the default font name used
 */
extern NSString *const kRTCFontName;
/**
 * kRTCFontName is the bold style of the default font
 */
extern NSString *const kRTCFontNameBold;


// Place settings
/**
 * kRTCPlaceNameMaxLength is the maximum length of place names
 */
extern const NSUInteger kRTCPlaceNameMaxLength;


// Location Settings
/**
 * kRTCLocationUpdateExpiryTime is the maximum age of location update that can be
 * considered valid. The smaller this value the more sensitive we are to location
 * changes.
 * If you get a location update that falls within this expiry
 * time window, turn off updates to save power.
 */
extern const NSTimeInterval kRTCLocationUpdateExpiryTime;

/**
 * kRTCLocationAccuracyMax is the maximum acceptable accuracy of a location
 * update
 */
extern const CLLocationAccuracy kRTCLocationAccuracyMax;

/**
 * kRTCLocationAccuracyThreshold is the upper bound of the accuracy values below
 * which a location update is deemed good enough.
 * If possible make this > 10;
 */
extern const CLLocationAccuracy kRTCLocationAccuracyThreshold;

/**
 * kRTCLocationAccuracySignificantChange is the minimum change in accuracy which
 * we consider to be significant enough when determining if accuracy has changed
 */
extern const CLLocationAccuracy kRTCLocationAccuracySignificantChange;

/**
 * kRTCLocationAttemptsMax is the maximum number of attempts we can make when
 * trying to get an accurate location.
 * This value really should be something <= 10. Anything more is asking
 * for a really slow location determination. Here are some statistics to aid in
 * choosing this value:
 *  location accuracy    max number of attempts
 *  ~1000                2
 *  ~100                 4
 *  50                   6
 *  10                   8
 *  5                    10
 */
extern const NSUInteger kRTCLocationAttemptsMax;

/** 
 * kRTCMaxWaitTimeForBetterResult is the maximum wait time (in seconds) after 
 * getting a location update that we hold off for a better location update. 
 * If we don't get a better update in this time window we end operations and
 * take the best location so far..
 */
extern const NSTimeInterval kRTCLocationMaxWaitTimeForBetter;

/**
 * kRTCLocationUpdateTimeout is the maximum wait (in seconds) for getting first 
 * location update.
 */
extern const NSTimeInterval kRTCLocationMaxWaitTimeForFirst;

// Notifications
/**
 * NSNotification identifier for Retrac's managedObjectContext availability
 */
extern NSString *const kRTCMOCAvailableNotification;

/**
 * NSNotification identifier for Retrac's managedObjectContext deletion
 */
extern NSString *const kRTCMOCDeletedNotification;


// Application Error Strings
/**
 * kRTCErrorMsgLocationDisabled is the error message shown when location services 
 * are disabled
 */
extern NSString *const kRTCErrorMsgLocationDisabled;