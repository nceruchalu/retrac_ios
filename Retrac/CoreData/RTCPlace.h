//
//  RTCPlace.h
//  Retrac
//
//  Created by Nnoduka Eruchalu on 7/31/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>


@interface RTCPlace : NSManagedObject

@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) CLLocation * location;
@property (nonatomic, retain) CLPlacemark * placemark;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * timeout;

@end
