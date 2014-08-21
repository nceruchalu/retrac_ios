//
//  RTCPlace+MKAnnotation.m
//  Retrac
//
//  Created by Nnoduka Eruchalu on 8/2/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "RTCPlace+MKAnnotation.h"

@implementation RTCPlace (MKAnnotation)

- (CLLocationCoordinate2D)coordinate
{
    return self.location.coordinate;
}

- (NSString *)title
{
    return self.name;
}

@end
