//
//  RTCConstants.m
//  Retrac
//
//  Created by Nnoduka Eruchalu on 7/31/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "RTCConstants.h"

// Input borders
const CGFloat kRTCInputBorderThickness      = 1.0f;
const CGFloat kRTCInputBorderRadius         = 5.0f;

// Default font name
NSString *const kRTCFontName                = @"Avenir-Light";
NSString *const kRTCFontNameBold            = @"Avenir-Medium";

// Place Settings
const NSUInteger kRTCPlaceNameMaxLength     = 100;

// Location Settings
const NSTimeInterval kRTCLocationUpdateExpiryTime       = 5.0;
const CLLocationAccuracy kRTCLocationAccuracyMax        = 100.0;
const CLLocationAccuracy kRTCLocationAccuracyThreshold  = 15.0;
const CLLocationAccuracy kRTCLocationAccuracySignificantChange = 0.0;
const NSUInteger kRTCLocationAttemptsMax                = 10;
const NSTimeInterval kRTCLocationMaxWaitTimeForBetter   = 5.0;
const NSTimeInterval kRTCLocationMaxWaitTimeForFirst    = 30.0;

// Notifications
NSString *const kRTCMOCAvailableNotification    = @"kRTCMOCAvailableNotification";
NSString *const kRTCMOCDeletedNotification      = @"kRTCMOCDeletedNotification";

// Application Error Strings
NSString *const kRTCErrorMsgLocationDisabled    = @"You have to enable your location in your device settings to save and navigate to places.";
