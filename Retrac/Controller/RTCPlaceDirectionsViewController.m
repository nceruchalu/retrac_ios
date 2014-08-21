//
//  RTCPlaceDirectionsViewController.m
//  Retrac
//
//  Created by Nnoduka Eruchalu on 8/2/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "RTCPlaceDirectionsViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "RTCRouteStepTableViewCell.h"
#import "RTCPlace+MKAnnotation.h"
#import "RTCPlace+Location.h"
#import "RTCLocationManager.h"
#import "RTCPlaceDetailsViewController.h"
#import "MKMapView+Location.h"

// Constants
static const CLLocationDistance kMetersInFoot   = 0.3048;
static const CLLocationDistance kMetersInMile   = 1609.34;
// set the minimum mileage, below which distances are reported in feet.
static const CLLocationDistance kMinimumMiles    = 0.1;

static const CGFloat kRouteLineWidth  = 5.0;

// messages to show when directions available or not.
static NSString *const kPlaceDirectionsMsg  = @"Walking Directions";
// shown in table view header
static NSString *const kNoDirectionsMsg     = @"Walking Directions Not Available";
// shown in navigation item titleView
static NSString *const kNoDirectionsMsgCondensed = @"No Directions Available";

// View Controller title
static NSString *const kNavigationItemTitle = @"Place Directions";
static const CGFloat kNavigationItemTitleFontSize = 14.0;

// seconds in minute, hour, day per the Gregorian Calendar.
static const NSInteger kSecondsInMinute     = 60;
static const NSInteger kSecondsInHour       = 3600;
static NSString *const kMinuteUnit          = @"minute";
static NSString *const kMinutesUnit         = @"minutes";
static NSString *const kHourUnit            = @"hour";
static NSString *const kHoursUnit           = @"hours";

@interface RTCPlaceDirectionsViewController () <UITableViewDataSource,
                                                UITabBarControllerDelegate,
                                                MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *directionsMapView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *openMapsButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (strong, nonatomic) UILabel *navigationItemTitleLabel;

/**
 * Walking route between current location and destination
 */
@property (strong, nonatomic) MKRoute *walkingRoute;

// Cache source and destination mapItems used to make walkingRoute
@property (strong, nonatomic) MKMapItem *walkingRouteSource;
@property (strong, nonatomic) MKMapItem *walkingRouteDestination;

/**
 * Properties used for getting user's current location and corresponding annotation
 */
@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) MKPointAnnotation *locationAnnotation;

@end

@implementation RTCPlaceDirectionsViewController

#pragma mark - Properties

- (void)setWalkingRoute:(MKRoute *)walkingRoute
{
    _walkingRoute = walkingRoute;
    
    // set new overlay on mapView
    [self.directionsMapView removeOverlays:self.directionsMapView.overlays];
    if (walkingRoute) {
        [self.directionsMapView addOverlay:walkingRoute.polyline level:MKOverlayLevelAboveRoads];
    }
    
    // update navigation item titleView
    [self updateNavigationItemTitle];
    
    // reload directions table
    [self.tableView reloadData];
    
    // enable/disable maps button
    [self updateOpenMapsButton:(walkingRoute != nil)];
}

- (void)setDestinationPlace:(RTCPlace *)destinationPlace
{
    _destinationPlace = destinationPlace;
    [self updateLocationViews];
}

- (void)setLocation:(CLLocation *)location
{
    _location = location;
    [self updateLocationViews];
}

- (MKPointAnnotation *)locationAnnotation
{
    // lazy instantiation
    if (!_locationAnnotation) {
        _locationAnnotation = [[MKPointAnnotation alloc] init];
        _locationAnnotation.title = @"Current Location";
    }
    return _locationAnnotation;
}


#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set titleView of navigationItem to a 2-line label
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.numberOfLines = 2;
    label.font = [UIFont boldSystemFontOfSize:kNavigationItemTitleFontSize];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    self.navigationItem.titleView = label;
    
    self.navigationItemTitleLabel = label; // cache label
    [self updateNavigationItemTitle];
    
    [self updateLocationViews];
    
    // setup mapView
    self.directionsMapView.delegate = self;
    
    // disable maps button on startup. It will be enabled when appropriate
    [self updateOpenMapsButton:NO];
    
    // ensure we have destination placemark which is required for routing
    if (!self.destinationPlace.placemark) {
        [[[CLGeocoder alloc] init] reverseGeocodeLocation:self.destinationPlace.location completionHandler:^(NSArray *placemarks, NSError *error) {
            // cache location placemark
            CLPlacemark *placemark = [placemarks lastObject];
            if (placemark) {
                self.destinationPlace.placemark = placemark;
                [self updateMapViewRoute];
            }
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // show user location on mapview
    self.directionsMapView.showsUserLocation = YES;
    
    // each time view re-appears re-route the user based on current location by
    // simply updating current location
    [self updateCurrentLocation];
    
    // clear any selection in the tableview before it is displayed
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // after the tableview has been displayed, flash the scroll view's scroll
    // indicators.
    [self.tableView flashScrollIndicators];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // remove user location from mapview
    self.directionsMapView.showsUserLocation = NO;
}


#pragma mark - Instance Methods
#pragma mark Private
/**
 * convert meters to a string representation in feet (if < kMinimumMiles miles) or miles
 * (if >= kMinimumMiles miles)
 */
- (NSString *)metersToImperial:(CLLocationDistance)distanceMeters
{
    NSString *distanceImperial = nil;
    
    if (distanceMeters >= kMetersInMile * kMinimumMiles) {
        distanceImperial = [NSString stringWithFormat:@"%.1f mi",(distanceMeters/kMetersInMile)];
    } else if (distanceMeters >= 0) {
        distanceImperial = [NSString stringWithFormat:@"%d ft", (int)(distanceMeters/kMetersInFoot)];
    }
    
    return distanceImperial;
}

/**
 * Convert a time interval to a string representation that appears as one of the following:
 * - mm minutes(s)
 * - hh hour(s)
 * - hh hour(s) mm minute(s)
 */
- (NSString *)timeIntervalToString:(NSTimeInterval)timeSeconds
{
    NSString *formattedTime = nil;
    // ensure timeSeconds is >= 0
    int numSeconds = abs(timeSeconds);
    
    int hours = numSeconds / kSecondsInHour;
    int minutes = (numSeconds % kSecondsInHour) / kSecondsInMinute;
    
    NSString *hoursUnits = (hours == 1) ? kHourUnit : kHoursUnit;
    NSString *minutsUnits = (minutes == 1) ? kMinuteUnit : kMinutesUnit;
    
    if (hours == 0) {
        formattedTime = [NSString stringWithFormat:@"%d %@", minutes, minutsUnits];
    } else if ((minutes == 0) && (hours > 0)) {
        formattedTime = [NSString stringWithFormat:@"%d %@", hours, hoursUnits];
    } else {
        formattedTime = [NSString stringWithFormat:@"%d %@ %d %@", hours, hoursUnits, minutes, minutsUnits];
    }
    
    return formattedTime;
}

/**
 * Setup Location services by configuring location manager if allowed or showing
 * an error alert.
 */
- (void)updateCurrentLocation
{
    [self.spinner startAnimating];
    [self updateOpenMapsButton:NO];
    
    [[RTCLocationManager sharedManager] updateCurrentLocation:^(CLLocation *location, NSError *error) {
        [self.spinner stopAnimating];
        
        if (location) {
            // set new location and the setter will do a lot for us.
            self.location = location;
        }
        
    } failure:^{
        [self.spinner stopAnimating];
    }];
}


/**
 * Update mapView and tableView using the current location and the 
 * destinationPlace property
 */
- (void)updateLocationViews
{
    // update navigation item titleView
    [self updateNavigationItemTitle];
    
    // Setup annotations on map
    [self updateMapViewAnnotations];
   
    // Setup directions route on map
    [self updateMapViewRoute];
}

/**
 * Update navigation item titleView
 */
- (void)updateNavigationItemTitle
{
    NSString *firstLine = [self.destinationPlace.name length] ? self.destinationPlace.name : kNavigationItemTitle;
    firstLine = [NSString stringWithFormat:@"%@\n",firstLine];
    
    NSString *secondLine;
    if (self.walkingRoute) {
        NSString *time = [self timeIntervalToString:self.walkingRoute.expectedTravelTime];
        NSString *distance = [self metersToImperial:self.walkingRoute.distance];
        secondLine = [NSString stringWithFormat:@"%@ - %@", time, distance];
    } else {
        secondLine = kNoDirectionsMsgCondensed;
    }
    
    UIFont *firstLineFont = [UIFont boldSystemFontOfSize:kNavigationItemTitleFontSize];
    NSDictionary *firstLineAttributes = @{NSFontAttributeName: firstLineFont};
    NSMutableAttributedString *firstLineAttrStr = [[NSMutableAttributedString alloc] initWithString:firstLine attributes:firstLineAttributes];
    
    UIFont *secondLineFont = [UIFont systemFontOfSize:kNavigationItemTitleFontSize];
    NSDictionary *secondLineAttributes = @{NSFontAttributeName: secondLineFont};
    NSMutableAttributedString *secondLineAttrStr = [[NSMutableAttributedString alloc] initWithString:secondLine attributes:secondLineAttributes];
    
    UILabel *label = self.navigationItemTitleLabel;
    [firstLineAttrStr appendAttributedString:secondLineAttrStr];
    label.attributedText = firstLineAttrStr;
    [label sizeToFit];

}

/**
 * Update mapview annotations
 */
- (void)updateMapViewAnnotations
{
    // update destination place annotation on mapview
    [self.directionsMapView removeAnnotation:self.destinationPlace];
    [self.directionsMapView addAnnotation:self.destinationPlace];
    
    // update current location annotation on mapview
    if (self.location) {
        [self.directionsMapView removeAnnotation:self.locationAnnotation];
        self.locationAnnotation.coordinate = self.location.coordinate;
        [self.directionsMapView addAnnotation:self.locationAnnotation];
    }
    
    // zoom in to these annotations
    [self.directionsMapView zoomToAnnotations];
}

/**
 * Update displayed mapview route
 */
- (void)updateMapViewRoute
{
    // always have a destination, but location is not guaranteed
    if (self.location && self.destinationPlace.placemark) {
        // Create walking directions request
        MKDirectionsRequest *walkingRouteRequest = [[MKDirectionsRequest alloc] init];
        walkingRouteRequest.transportType = MKDirectionsTransportTypeWalking;
        
        // Get necessary placemarks and map items
        self.walkingRouteSource = [MKMapItem mapItemForCurrentLocation];
        [walkingRouteRequest setSource:self.walkingRouteSource];
        
        
        MKPlacemark *destinationPlaceMark = [[MKPlacemark alloc] initWithPlacemark:self.destinationPlace.placemark];
        self.walkingRouteDestination = [[MKMapItem alloc] initWithPlacemark:destinationPlaceMark];
        [walkingRouteRequest setDestination:self.walkingRouteDestination];
        
        // get walking directions
        MKDirections *walkingRouteDirections = [[MKDirections alloc] initWithRequest:walkingRouteRequest];
        
        [walkingRouteDirections calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse * walkingRouteResponse, NSError *walkingRouteError) {
            if (walkingRouteError) {
                [self handleDirectionsError:walkingRouteError];
            } else {
                // The code doesn't request alternate routes, so add the single calculated route to
                // a previously declared MKRoute property called walkingRoute.
                self.walkingRoute = [walkingRouteResponse.routes firstObject];
            }
        }];
    }
}

/**
 * Enable/disable open maps button
 *
 * @param enabled   a Boolean value that determines whether the open maps button 
 *                  is enabled.
 */
- (void)updateOpenMapsButton:(BOOL)enabled
{
    UIImage *buttonImage = nil;
    if (enabled) buttonImage = [UIImage imageNamed:@"open-map"];

    // set appropriate button image and then enablement state.
    [self.openMapsButton setImage:buttonImage forState:UIControlStateNormal];
    self.openMapsButton.enabled = enabled;
}

/**
 * handle errors from trying to compute directions
 * This can occur for instance when trying to get a walking route for locations
 * on different continents.
 */
- (void)handleDirectionsError:(NSError *)routeError
{
    // clear out the walking route appropriately
    self.walkingRoute = nil;
}


#pragma mark - Target-Action Methods
/**
 * Ask the Maps apps to provide turn-by-turn directions
 */
- (IBAction)displayDirectionsInMaps:(id)sender
{
    // can only attempt redirecting to maps app if there is indeed data
    if (self.walkingRoute) {
        MKCoordinateRegion region = self.directionsMapView.region;

        // get map item representing user's current location
        MKMapItem *userLocationItem = [MKMapItem mapItemForCurrentLocation];
        //MKPlacemark *userLocationPlaceMark = [[MKPlacemark alloc] initWithCoordinate:self.directionsMapView.userLocation.coordinate addressDictionary:nil];
        //MKMapItem *userLocationItem = [[MKMapItem alloc] initWithPlacemark:userLocationPlaceMark];
        
        
        // Open the item in Maps, specifying the map region to display.
        [MKMapItem openMapsWithItems:@[userLocationItem, self.walkingRouteDestination]
                       launchOptions:@{MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking,
                                       MKLaunchOptionsMapCenterKey : [NSValue valueWithMKCoordinate:region.center],
                                       MKLaunchOptionsMapSpanKey : [NSValue valueWithMKCoordinateSpan:region.span]}];
    }
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.walkingRoute.steps count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // get the cell
    static NSString *cellIdentifier = @"Route Cell";
    RTCRouteStepTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    // get corresponding route step
    MKRouteStep *routeStep = [self.walkingRoute.steps objectAtIndex:indexPath.row];
    
    // configure the cell with data from the route step
    cell.instructionsLabel.text = routeStep.instructions;
    cell.distanceLabel.text = [self metersToImperial:routeStep.distance];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.walkingRoute ? kPlaceDirectionsMsg : kNoDirectionsMsg;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}


#pragma mark - MKMapViewDelegate
/**
 * The mapView calls this to get the MKAnnotationView for a given id <MKAnnotation>
 * this implementation returns a standard MKPinAnnotationView
 */
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    // If the annotation is the user location, we already have an annotation so
    // just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    // Handle any custom annotations.
    if ([annotation isKindOfClass:[RTCPlace class]]) {
        // This is a destination Place annotation
        
        // Try to dequeue an existing pin view first
        static NSString *kDestinationPlaceIdentifier = @"DestinationPlaceAnnotation";
        
        MKPinAnnotationView *pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:kDestinationPlaceIdentifier];
        
        if (!pinView) {
            // If an existing pin view was not available, create one.
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                      reuseIdentifier:kDestinationPlaceIdentifier];
            pinView.pinColor = MKPinAnnotationColorRed;
            pinView.animatesDrop = YES;
            pinView.canShowCallout = YES;
        } else {
            pinView.annotation = annotation;
        }
        return pinView;
        
    } else if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
        // This is a user location annotation
        
        // Try to dequeue an existing pin view first.
        static NSString *kUserLocationIdentifier = @"CurrentLocationAnnotation";
        MKPinAnnotationView *pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:kUserLocationIdentifier];
         
        if (!pinView) {
            // If an existing pin view was not available, create one.
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                      reuseIdentifier:kUserLocationIdentifier];
            pinView.pinColor = MKPinAnnotationColorGreen;
            pinView.animatesDrop = YES;
            pinView.canShowCallout = YES;
            
            // If appropriate, customize the callout by adding accessory views.
            // Not so in this case
        }
        else {
            pinView.annotation = annotation;
        }
        
        return pinView;
        
    }
    
    return nil;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKPolyline class]])
    {
        MKPolylineRenderer *aRenderer = [[MKPolylineRenderer alloc] initWithPolyline:(MKPolyline *)overlay];
        
        aRenderer.fillColor = kRTCLocationColor;
        aRenderer.strokeColor = kRTCLocationColor;
        aRenderer.lineWidth = kRouteLineWidth;
        
        return aRenderer;
    }
    
    return nil;
}


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showPlaceDetailsFromDirections"]) {
        if ([segue.destinationViewController isKindOfClass:[RTCPlaceDetailsViewController class]]) {
            RTCPlaceDetailsViewController *detailsVC = (RTCPlaceDetailsViewController *)segue.destinationViewController;
            detailsVC.place = self.destinationPlace;
        }
    }
}

@end
