//
//  RTCLocationViewController.m
//  Retrac
//
//  Created by Nnoduka Eruchalu on 7/31/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "RTCLocationViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "RTCPlace+Location.h"
#import "RTCModelManager.h"
#import "RTCLocationManager.h"
#import "SVPulsingAnnotationView.h"
#import "MKMapView+Location.h"

@interface RTCLocationViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet MKMapView *locationMapView;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;

// view placed on top of keyboard
@property (weak, nonatomic) IBOutlet UIToolbar *accessoryView;


// location-related properties
@property (strong, nonatomic, readwrite) CLLocation *location;   // cached location
@property (strong, nonatomic) CLPlacemark *placemark; // reverse-geocoded placemark
@property (strong, nonatomic) MKPointAnnotation *locationAnnotation; // annotation to be placed on mapview

/**
 * internal handle to the database
 */
@property (strong, nonatomic, readwrite) NSManagedObjectContext *managedObjectContext;

@end

@implementation RTCLocationViewController


#pragma mark - Properties
- (MKPointAnnotation *)locationAnnotation
{
    // lazy instantiation
    if (!_locationAnnotation) {
        _locationAnnotation = [[MKPointAnnotation alloc] init];
        _locationAnnotation.title = @"Current Location";
    }
    return _locationAnnotation;
}

/**
 * This view controller cannot save until the managed object context is set
 */
- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    // managed object context has been setup so enable/disable VC for user saving
    if (!managedObjectContext) {
        [self disableSaveButton:NO];
    } else {
        // only enable save button if there's a location to save
        if (self.location) [self enableSaveButton];
    }
}

/**
 * Setting location means we should update location input buttons and mapview
 */
- (void)setLocation:(CLLocation *)location
{
    _location = location;
    
    // allow modification of location-related fields if there's a location
    if (location) {
        [self enableLocationInputs];
    } else {
        [self disableLocationInputs];
    }
    
    // update current user location annotation on mapview using following steps
    // 1: first remove current annotation on map.
    // 2: update annotation's coordinates
    // 2: add annotation object to map
    [self.locationMapView removeAnnotation:self.locationAnnotation];
    self.locationAnnotation.coordinate = location.coordinate;
    [self.locationMapView addAnnotation:self.locationAnnotation];
    [self.locationMapView zoomToAnnotations];
}

/**
 * Setting placemark means we should update the displayed address
 */
- (void)setPlacemark:(CLPlacemark *)placemark
{
    _placemark = placemark;
    
    // update address in UI
    self.addressLabel.text = [RTCPlace addressFromPlacemark:placemark];
    
    // update place name in UI but truncate it to be within maxlength chars
    self.nameTextField.text = [RTCPlace truncatedName:placemark.name];
}

#pragma mark - Class Methods
#pragma mark Public
/**
 * Configure button to have a visible border with rounded corners. The border 
 * color is the same color as the button currentTitleColor property
 *
 * @param button    button to be configured
 */
+ (void)addRoundedBorder:(UIButton *)button
{
    button.layer.cornerRadius = kRTCInputBorderRadius;
    button.clipsToBounds = YES;
    button.layer.borderWidth = kRTCInputBorderThickness;
    button.layer.borderColor = button.currentTitleColor.CGColor;
}


#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // setup keyboard accessory view
    self.nameTextField.inputAccessoryView = self.accessoryView;
    
    // set mapView delegate
    self.locationMapView.delegate = self;
    
    // configure buttons to have rounded borders
    [RTCLocationViewController addRoundedBorder:self.refreshButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // get handle to database... doing this first because it enables save button
    // which I might want to disable later
    self.managedObjectContext = [RTCModelManager sharedManager].managedObjectContext;
    
    if (!self.location) {
        // if no location, then disable user inputs till this exists
        [self disableUserInteraction];
    } else {
        // if there is a location check that it's still valid else disable save
        // button.
        NSTimeInterval howRecent = [self.location.timestamp timeIntervalSinceNow];
        if (abs(howRecent) >= kRTCLocationUpdateExpiryTime) [self disableSaveButton:NO];
    }
    
    // update current location
    [self updateCurrentLocation];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(managedObjectContextReady:)
                                                 name:kRTCMOCAvailableNotification
                                               object:nil];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // remove observers
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kRTCMOCAvailableNotification
                                                  object:nil];
}


#pragma mark - Instance Methods
#pragma mark Public (Abstract)
/**
 * Enable view controller to allow user saving
 */
- (void)enableSaveButton
{
    // abstract
}

/**
 * Disable save button and indicate if this is because of a successful save.
 */
- (void)disableSaveButton:(BOOL)saved
{
    // abstract
}


#pragma mark Private
/**
 * Setup Location services by configuring location manager if allowed or showing
 * an error alert.
 */
- (void)updateCurrentLocation
{
    [self.spinner startAnimating];
    self.nameTextField.textColor = [UIColor lightGrayColor];
    
    [[RTCLocationManager sharedManager] updateCurrentLocation:^(CLLocation *location, NSError *error) {
        [self.spinner stopAnimating];
        self.nameTextField.textColor = [UIColor blackColor];
        
        if (!location) {
            [self disableSaveButton:NO];
        } else {
            // cache location and get placemark
            self.location = location;
            
            [[[CLGeocoder alloc] init] reverseGeocodeLocation:self.location completionHandler:^(NSArray *placemarks, NSError *error) {
                // cache location placemark
                self.placemark = [placemarks lastObject];
            }];
            
            // now that we have a new location we can enable save if there's a context
            if (self.managedObjectContext) [self enableSaveButton];
        }
        
    } failure:^{
        [self.spinner stopAnimating];
        self.nameTextField.textColor = [UIColor blackColor];
        [self disableUserInteraction];
    }];
}


/**
 * Create place from values of elements in View Controller and save in CoreData
 *
 * This expects the managedObjectContext and location to be ready else it won't 
 * create a place.
 *
 * @see shouldPerformSegueWithIdentifier:sender: and saveLocation:
 */
- (RTCPlace *)createPlace
{
    // If the shared managed object context has already been setup use it
    // Notice we don't try to asynchronously setup the managedObjectContext
    //   as the place creation should be blocked until the context and location
    //   are ready.
    RTCPlace *createdPlace = nil;
    if (self.managedObjectContext && self.location) {
        createdPlace = [RTCPlace placeWithName:self.nameTextField.text location:self.location placemark:self.placemark inManagedObjectContext:self.managedObjectContext];
    }
    return createdPlace;
}

- (void)enableLocationInputs
{
    self.nameTextField.enabled = YES;
    self.refreshButton.enabled = YES;
    [RTCLocationViewController addRoundedBorder:self.refreshButton];
}

/**
 * Disable user actions in view controller
 */
- (void)disableUserInteraction
{
    [self disableSaveButton:NO];
    [self disableLocationInputs];
}

- (void)disableLocationInputs
{
    self.nameTextField.enabled = NO;
    self.refreshButton.enabled = NO;
    [RTCLocationViewController addRoundedBorder:self.refreshButton];
}



#pragma mark Notification Observer Methods

/**
 * ManagedObjectContext now available from RTCModelManager so update local copy
 */
- (void)managedObjectContextReady:(NSNotification *)aNotification
{
    self.managedObjectContext = [RTCModelManager sharedManager].managedObjectContext;
}


#pragma mark - Target-Action Methods
- (IBAction)hideKeyboard:(id)sender
{
    // force view to resignFirstResponder status
    [self.view endEditing:YES];
}

- (IBAction)saveLocation:(id)sender
{
    if (self.managedObjectContext && self.location) {
        [self createPlace];
        // disable further saving until we get a new location
        [self disableSaveButton:YES];
    }
}

- (IBAction)refreshLocation:(id)sender
{
    [self updateCurrentLocation];
}


#pragma mark - UITextFieldDelegate
/**
 * Implement maxLength on name text field
 *
 * Before the text field changes, the UITextField asks the delegate if the specified
 * text should be changed. The text field has not changed at this point, so we
 * grab it's current length and the string length we're inserting, minus the range
 * length. If this value is too long (more than kRTCPlaceNameMaxLength characters),
 * return `NO` to prohibit the change.
 *
 * When typing in a single character at the end of a text field, the `range.location`
 * will be the current field's length, and `range.length` will be 0 because we're
 * not replacing/deleting anything. Inserting into the middle of a text field just
 * means a different `range.location`, and pasting multiple characters just means
 * `string` has more than one character in it.
 *
 * Deleting single characters or cutting multiple characters is specified by a
 * `range` with a non-zero length, and an empty string. Replacement is just a
 * range deletion with a non-empty string.
 *
 * ref: http://stackoverflow.com/a/1773257
 */
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > kRTCPlaceNameMaxLength) ? NO : YES;
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
    if ([annotation isKindOfClass:[MKPointAnnotation class]])
    {
        // Try to dequeue an existing pin view first.
        static NSString *kUserLocationIdentifier = @"CurrentLocationAnnotation";
        
        SVPulsingAnnotationView  *pulsingView = (SVPulsingAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:kUserLocationIdentifier];
        
        if (!pulsingView) {
            // If an existing pin view was not available, create one.
            pulsingView = [[SVPulsingAnnotationView alloc] initWithAnnotation:annotation
                                                              reuseIdentifier:kUserLocationIdentifier];
            pulsingView.annotationColor = kRTCLocationColor;
            pulsingView.canShowCallout = YES;
        } else {
            pulsingView.annotation = annotation;
        }
        return pulsingView;
    }
    
    return nil;
}


@end
