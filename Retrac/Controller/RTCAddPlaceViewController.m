//
//  RTCAddPlaceViewController.m
//  Retrac
//
//  Created by Nnoduka Eruchalu on 8/1/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "RTCAddPlaceViewController.h"

static NSString *const kUnwindSegueIdentifier = @"AddPlace";

@interface RTCAddPlaceViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveBarButton;

// VC's output is readwrite internally so it can be modified
@property (strong, nonatomic, readwrite) RTCPlace *createdPlace;

@end

@implementation RTCAddPlaceViewController

#pragma mark - Instance Methods
#pragma mark Concrete
- (void)enableSaveButton
{
    [super enableSaveButton];
    self.saveBarButton.enabled = YES;
}

- (void)disableSaveButton:(BOOL)saved
{
    [super disableSaveButton:saved];
    self.saveBarButton.enabled = NO;
}

#pragma mark Target-Action Methods
- (IBAction)cancel
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Create the place!
    if ([segue.identifier isEqualToString:kUnwindSegueIdentifier]) {
        self.createdPlace = [self createPlace];
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    // Can only unwind and create a place if managedObjectContext is ready and
    // there is a location
    if ([identifier isEqualToString:kUnwindSegueIdentifier]) {
        if (!(self.managedObjectContext && self.location)) {
            return NO;
        }
    }
    return YES;
}

@end
