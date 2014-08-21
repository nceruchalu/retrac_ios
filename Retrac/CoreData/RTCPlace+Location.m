//
//  RTCPlace+Location.m
//  Retrac
//
//  Created by Nnoduka Eruchalu on 8/1/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "RTCPlace+Location.h"

// pull this in so we can use ABCreateStringWithAddressDictionary()
//#import <AddressBookUI/AddressBookUI.h>

#pragma mark - Constants
// seconds in minute, hour, day per the Gregorian Calendar.
static const NSInteger kSecondsInMinute    = 60;
static const NSInteger kSecondsInHour      = 3600;
static const NSInteger kSecondsInDay       = 86400;

@implementation RTCPlace (Location)

#pragma mark - Class Methods
#pragma mark Public

+ (NSString *)addressFromPlacemark:(CLPlacemark *)placemark
{
    NSString *address = nil;
    
    // Could use the AddressBook framework to create an address dictionary
    // but it keeps returning newlines and country name which just makes this
    // string too long
    /*
    NSString *addressString = CFBridgingRelease(CFBridgingRetain(ABCreateStringWithAddressDictionary(self.placemark.addressDictionary, NO)));
    */
    
    // get basic address element
    NSString *streetNumber = placemark.subThoroughfare;
    NSString *street = placemark.thoroughfare;
    NSString *city = placemark.locality;
    NSString *state = placemark.administrativeArea;
    NSString *postalCode = placemark.postalCode;
    
    // get formatted street
    NSString *formattedStreet = nil;
    if (streetNumber && street) {
        formattedStreet = [NSString stringWithFormat:@"%@ %@", streetNumber, street];
    } else if (street) {
        formattedStreet = street;
    }
    
    if (formattedStreet || city || state) {
        NSMutableString *formattedAddress = [[NSMutableString alloc] initWithString:@""];
        BOOL firstComponent = YES; // are we on first component?
        
        if (formattedStreet) {
            [formattedAddress appendString:formattedStreet];
            firstComponent = NO;
        }
        
        if (city) {
            if (!firstComponent) [formattedAddress appendString:@", "];
            [formattedAddress appendString:city];
            firstComponent = NO;
        }
        
        if (state) {
            if (!firstComponent) [formattedAddress appendString:@", "];
            [formattedAddress appendString:state];
            firstComponent = NO;
        }
        
        if (postalCode) {
            [formattedAddress appendString:@" "];
            [formattedAddress appendString:postalCode];
        }
        
        address = [formattedAddress copy];
     }
    
    return address;
}

+ (NSString *)truncatedName:(NSString *)name
{
    // truncate argument name to be within maxlength chars with following steps:
    // 1: define the range you're interested in
    NSRange stringRange = {0, MIN([name length], kRTCPlaceNameMaxLength)};
    
    // 2: adjust the range to include dependent chars
    stringRange = [name rangeOfComposedCharacterSequencesForRange:stringRange];
    
    // 3: now you can create the truncated string
    NSString *truncatedName = [name substringWithRange:stringRange];
    
    return truncatedName;
}

+ (NSString *)timeLabelForPlaceDate:(NSTimeInterval)placeTime
{
    NSString *timeLabel = nil;
    
    if (placeTime >= kSecondsInDay) {
        timeLabel = [NSString stringWithFormat:@"%dd",(int)(placeTime/kSecondsInDay)];
    } else if (placeTime >= kSecondsInHour) {
        timeLabel = [NSString stringWithFormat:@"%dh",(int)(placeTime/kSecondsInHour)];
    } else if (placeTime >= 0) {
        timeLabel = [NSString stringWithFormat:@"%dm",(int)(placeTime/kSecondsInMinute)];
    }
    
    return timeLabel;
}

+ (instancetype)placeWithName:(NSString *)name
                     location:(CLLocation *)location
                    placemark:(CLPlacemark *)placemark
       inManagedObjectContext:(NSManagedObjectContext *)context
{
    RTCPlace *place = [NSEntityDescription insertNewObjectForEntityForName:@"RTCPlace" inManagedObjectContext:context];
    
    place.creationDate = [NSDate date];
    place.location = location;
    place.placemark = placemark;
    place.name = name;
    
    return place;
}

#pragma mark - Instance Methods
#pragma mark Public
- (NSString *)timeSinceCreation
{
    NSTimeInterval intervalSinceCreation = -1 * [self.creationDate timeIntervalSinceNow];
    return [RTCPlace timeLabelForPlaceDate:intervalSinceCreation];
}

@end
