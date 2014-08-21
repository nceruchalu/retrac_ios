//
//  RTCLocationManager.m
//  Retrac
//
//  Created by Nnoduka Eruchalu on 8/3/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "RTCLocationManager.h"
#import <CoreLocation/CoreLocation.h>

@interface RTCLocationManager () <CLLocationManagerDelegate>


// number of location determination attempts
@property (nonatomic) NSUInteger numAttempts;

@property (nonatomic, strong) RTCLocationManagerCompletion completionBlock;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *bestLocation;             // best location so far
@property (strong, nonatomic, readwrite) CLLocation *location;      // cached location

@end


@implementation RTCLocationManager

#pragma mark - Properties
@synthesize locationManager = _locationManager;

- (CLLocationManager *)locationManager
{
    // lazy instantiation
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (void)setLocationManager:(CLLocationManager *)locationManager
{
    // cleanup first
    [_locationManager stopUpdatingLocation];
    // now update instance variable
    _locationManager = locationManager;
}

#pragma mark - Class methods
#pragma mark Public
// Declare a static variable, which is an instance of this class
// It is initialized once and only once in a thread-safe manner by using
//   Grand Central Dispatch (GCD)
+ (instancetype)sharedManager
{
    static RTCLocationManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initPrivate];
    });
    return sharedInstance;
}

/**
 * Show error message indicating location is disabled for app
 */
+ (void)showLocationDisabledErrorAlert
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops. That didn't work!" message:kRTCErrorMsgLocationDisabled delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}


#pragma mark - Initialization
// ideally we would make the designated initializer of the superclass call
//   the new designated initializer, but that doesn't make sense in this case.
// if a programmer calls [RTCLocationManager alloc] init], let them know the error
//   of their ways.
- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use + [RTCLocationManager sharedManager]"
                                 userInfo:nil];
    return nil;
}

// here is the real (secret) initializer
// this is the official designated initializer so it will call the designated
//   initializer of the superclass
- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        // custom initialization here...
    }
    return self;
}

#pragma mark - Deallocation
- (void)dealloc
{
    // stop and clear location manager
    self.locationManager = nil;
    
    [self cancelPerformStopUpdatingLocationWithBestResult];
}


#pragma mark - Instance Methods
#pragma mark Private
/**
 * Configure location manager for high accuracy (as this is a navigation app).
 *
 * @param locationManager   location manager to be configured
 */
- (void)configureLocationManager
{
    // If appropriate, configure the manager according to what kind of location
    // updating you want.
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    // Set a movement threshold for new events
    self.locationManager.distanceFilter = kCLDistanceFilterNone; // tracks all movements
    
    // Then start the manager monitoring for location changes
    [self.locationManager startUpdatingLocation];
}

/**
 * Setup location manager if we are authorized to or show an error message
 *
 * @param failure       block to be called when location services are disabled and
 *      after showing an error message.
 */
- (void)setupLocationServices:(void (^)())failure
{
    // First check if the hardware you are on/user supports location updating
    CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
    BOOL locationEnabled = [CLLocationManager locationServicesEnabled];
    
    if ((authStatus == kCLAuthorizationStatusDenied) ||
        (authStatus == kCLAuthorizationStatusRestricted) ||
        !locationEnabled) {
        // show error if we aren't able to use location services for one of
        // following reasons:
        // - The user disables location services in the Settings app or System Preferences.
        // - The user denies location services for a specific app.
        // - The device is in Airplane mode and unable to power up the necessary hardware.
        [RTCLocationManager showLocationDisabledErrorAlert];
        if (failure) failure();
        
    } else {
        // If able to use location services, create location manager, and set
        // the delegate to receive location updates.
        // Location not guaranteed to be authorized yet (authStatus==kCLAuthorizationStatusAuthorized)
        // but we will try our luck and wait for the appropriate delegate callback.
        [self configureLocationManager];
    }
}

/**
 * Stop updating location and save best result so far as final result
 * Also cancel timeout event that was to do the same thing.
 */
- (void)stopUpdatingLocationWithBestResult
{
    // since this is happening now, cancel timeout events
    [self cancelPerformStopUpdatingLocationWithBestResult];
    
    [self.locationManager stopUpdatingLocation];
    self.location = self.bestLocation;
    if (self.completionBlock) {
        self.completionBlock(self.location, nil);
        self.completionBlock = nil; // prevent this block from being called again.
    }
}

/**
 * Cancel time-delayed request to stop updating location and save best result so 
 * far.
 */
- (void)cancelPerformStopUpdatingLocationWithBestResult {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopUpdatingLocationWithBestResult) object:nil];
}


#pragma mark Public
- (void)updateCurrentLocation:(RTCLocationManagerCompletion)completion failure:(void (^)())failure
{
    // stop any previously running operations
    [self cancelPerformStopUpdatingLocationWithBestResult];
    [self.locationManager stopUpdatingLocation];
    
    self.location = nil;  // clear out cached location as we are doing a refresh
    self.bestLocation = nil;
    self.numAttempts = 0; // restart attempts counter
    self.completionBlock = [completion copy]; // cache completion block
    
    // set update to timeout if we dont get the first location in expected window.
    [self performSelector:@selector(stopUpdatingLocationWithBestResult) withObject:nil afterDelay:kRTCLocationMaxWaitTimeForFirst];

    [self setupLocationServices:failure];
}


#pragma mark - CLLocationManagerDelegate
#pragma mark Responding to Location Events
/**
 * When the app first initializes you can be off in accuracy by 1000+ meters,
 * thus one location update is not going to cut it. 3+ updates should get you
 * within 100 meters accuracy. 
 * However there's a catch - each successive attempt is going to take longer and
 * longer to improve your accuracy, thus it gets expensive quickly.
 *
 * So here's what we do:
 * - Only process locations that are recent with valid accuracy
 * - Done if we get a location with accuracy under kRTCLocationAccuracyThreshold
 * - Cache a new location if it has significantly better accuracy or is first update.
 *   Significant change requires a change of kRTCLocationAccuracySignificantChange.
 * - Be sure to not go past max number of attempts defined in kRTCLocationAttemptsMax
 * - If we don't get any update after kRTCLocationMaxWaitTimeForFirst then end this.
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // If it's an acceptable location, turn off updates to save power.
    CLLocation *newLocation = [locations lastObject];
    
    // Test the age of the location measurement to determine if the measurement
    // is cached. We definitely don't want to rely on cached measurements
    // Also check the horizontal accuracy does not indicate an invalid measurement
    NSTimeInterval howRecent = [newLocation.timestamp timeIntervalSinceNow];
    if ((abs(howRecent) < kRTCLocationUpdateExpiryTime) &&
        (newLocation.horizontalAccuracy >= 0)) {
        
        if ((self.bestLocation == nil) ||
            (newLocation.horizontalAccuracy < (self.bestLocation.horizontalAccuracy - kRTCLocationAccuracySignificantChange))) {
            // this is first location update or new one with better accuracy than
            // best seen so far. So store this new location as "best effort"
            self.bestLocation = newLocation;
            
            // we have our result if new location's accuracy is under the threshold
            if (self.bestLocation.horizontalAccuracy <= kRTCLocationAccuracyThreshold) {
                // it is important that we minimize power by stopping the location
                // manager as quickly as possible
                [self stopUpdatingLocationWithBestResult];
                
            } else {
                // set timeout for how long we are willing to wait for a better result
                [self cancelPerformStopUpdatingLocationWithBestResult];
                [self performSelector:@selector(stopUpdatingLocationWithBestResult) withObject:nil afterDelay:kRTCLocationMaxWaitTimeForBetter];
            }
            
        }
        
        // Ensure number of attempts doesnt go to far
        if (++self.numAttempts >= kRTCLocationAttemptsMax) {
            [self stopUpdatingLocationWithBestResult];
            return;
        }
    }
        
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if ([error code] == kCLErrorDenied) {
        [RTCLocationManager showLocationDisabledErrorAlert];
        
        // stop updating location
        [self cancelPerformStopUpdatingLocationWithBestResult];
        [self stopUpdatingLocationWithBestResult];
    }
    
    // Note we ignored the location "unknown" error simply means the manager is
    // currently unable to get the location.
    // We can ignore this error for this scenario of getting a single location
    // fix, because we already have a timeout that will stop the location manager
    // to save power.
}

#pragma mark Responding to Authorization Changes
// Would implement methods for responding to authorization changes but
// `locationManager:didChangeAuthorizationStatus:` keeps getting called multiple
// times. Simply inefficient.



@end
