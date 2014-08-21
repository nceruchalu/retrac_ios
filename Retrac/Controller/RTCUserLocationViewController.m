//
//  RTCUserLocationViewController.m
//  Retrac
//
//  Created by Nnoduka Eruchalu on 8/4/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "RTCUserLocationViewController.h"

// Constants
static NSString *const kSaveButtonTitle = @"Save";       // before save
static NSString *const kSaveButtonTitleSaved = @"Saved"; // after save

@interface RTCUserLocationViewController ()

@property (weak, nonatomic) IBOutlet UIButton *saveButton;

@end

@implementation RTCUserLocationViewController


#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // configure save button to match refresh button
    [RTCUserLocationViewController addRoundedBorder:self.saveButton];
}

#pragma mark - Instance Methods
#pragma mark Concrete
/**
 * Enable view controller to allow user saving
 */
- (void)enableSaveButton
{
    self.saveButton.enabled = YES;
    [RTCUserLocationViewController addRoundedBorder:self.saveButton];
    [self.saveButton setTitle:kSaveButtonTitle forState:UIControlStateNormal];
}

/**
 * Disable save button and indicate if this is because of a successful save.
 */
- (void)disableSaveButton:(BOOL)saved
{
    self.saveButton.enabled = NO;
    [RTCUserLocationViewController addRoundedBorder:self.saveButton];
    
    // configure button title
    NSString *buttonTitle = saved ? kSaveButtonTitleSaved : kSaveButtonTitle;
    [self.saveButton setTitle:buttonTitle forState:UIControlStateNormal];
}


@end
