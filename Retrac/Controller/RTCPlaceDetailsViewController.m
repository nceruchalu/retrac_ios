//
//  RTCPlaceDetailsViewController.m
//  Retrac
//
//  Created by Nnoduka Eruchalu on 8/2/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "RTCPlaceDetailsViewController.h"
#import "RTCPlace+Location.h"
#import <CoreLocation/CoreLocation.h>

@interface RTCPlaceDetailsViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (strong, nonatomic) IBOutlet UIToolbar *accessoryView;

@end


@implementation RTCPlaceDetailsViewController

#pragma mark - Properties
- (void)setPlace:(RTCPlace *)place
{
    _place = place;
    [self updatePlaceDetailsView];
}


#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // setup textfield
    self.nameTextField.delegate = self;
    self.nameTextField.inputAccessoryView = self.accessoryView;
    
    // display place name and address
    [self updatePlaceDetailsView];

    // start save button out disabled
    [self disableSaveButton];
    
    // ensure we have placemark required for displaying place address
    if (!self.place.placemark) {
        [[[CLGeocoder alloc] init] reverseGeocodeLocation:self.place.location completionHandler:^(NSArray *placemarks, NSError *error) {
            // cache location placemark
            CLPlacemark *placemark = [placemarks lastObject];
            if (placemark) {
                self.place.placemark = placemark;
                [self updatePlaceDetailsView];
            }
        }];
    }
}


#pragma mark - Instance Methods
#pragma mark Private
/**
 * Update displayed name and address from the model.
 */
- (void)updatePlaceDetailsView
{
    self.nameTextField.text = self.place.name;
    self.addressLabel.text = [RTCPlace addressFromPlacemark:self.place.placemark];
    
}

/**
 * Configure button to have a visible border with rounded corners.
 */
- (void)addRoundedBorder:(UIButton *)button
{
    button.layer.cornerRadius = kRTCInputBorderRadius;
    button.clipsToBounds = YES;
    button.layer.borderWidth = kRTCInputBorderThickness;
    button.layer.borderColor = button.currentTitleColor.CGColor;
}

/**
 * Disable save button
 */
- (void)disableSaveButton
{
    self.saveButton.enabled = NO;
    [self addRoundedBorder:self.saveButton];
}


#pragma mark - Target-Action methods
- (IBAction)saveChanges:(id)sender
{
    // only change that can be made is place name
    self.place.name = self.nameTextField.text;
    [self disableSaveButton];
}

- (IBAction)textFieldChanged:(id)sender
{
    self.saveButton.enabled = ![self.place.name isEqualToString:self.nameTextField.text];
    [self addRoundedBorder:self.saveButton];
}

- (IBAction)hideKeyboard:(id)sender
{
    // force view to resignFirstResponder status
    [self.view endEditing:YES];
}


#pragma mark - UITextFieldDelegate
/**
 * Implement maxLength on name text field
 *
 * @see RTCLocationViewController for detailed explanation
 * @ref http://stackoverflow.com/a/1773257
 */
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > kRTCPlaceNameMaxLength) ? NO : YES;
}

@end
