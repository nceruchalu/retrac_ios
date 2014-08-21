//
//  RTCAboutTVC.m
//  Retrac
//
//  Created by Nnoduka Eruchalu on 8/2/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "RTCAboutTVC.h"
#import <MessageUI/MessageUI.h>

/**
 * Constants for button indices in action sheets
 */
static const NSUInteger kTellAFriendMailButtonIndex = 0;    // Mail
static const NSUInteger kTellAFriendMessageButtonIndex = 1; // Message

/**
 * Constants for messages used to Tell Friends about the app
 */
static NSString *const kTellAFriendMailSubject = @"Retrac iPhone App";
static NSString *const kTellAFriendMailBody = @"Hey,\n\nI just downloaded Retrac on my iPhone.\n\nIt lets me save locations and retrace my steps.\n\nGet it now from http://RetracApp.com and say goodbye to forgetting where you parked!";
static NSString *const kTellAFriendMessageBody = @"Check out Retrac for your iPhone. Download it today from http://RetracApp.com";

/**
 * Constants for messages used to contact support
 */
static NSString *const kContactSupportMailSubject = @"Retrac Feedback";
static NSString *const kContactSupportMailBody = @"Please describe your problem here...";
static NSString *const kContactSupportMailAddress = @"support@RetracApp.com";

@interface RTCAboutTVC () <UIActionSheetDelegate,
                            MFMailComposeViewControllerDelegate,
                            MFMessageComposeViewControllerDelegate>

// keep outlets to all cells in static table view so we know which is clicked.
@property (weak, nonatomic) IBOutlet UITableViewCell *tellAFriendCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *contactSupportCell;

// keep track of the multiple actionsheets so we know which we are handling
@property (strong, nonatomic) UIActionSheet *tellAFriendActionSheet;

@end

@implementation RTCAboutTVC

#pragma mark - Properties
- (UIActionSheet *)tellAFriendActionSheet
{
    // lazy instantiation
    if (!_tellAFriendActionSheet) {
        _tellAFriendActionSheet = [[UIActionSheet alloc] initWithTitle:@"Tell a friend about Retrac via..."
                                                              delegate:self
                                                     cancelButtonTitle:@"Cancel"
                                                destructiveButtonTitle:nil
                                                     otherButtonTitles:@"Mail", @"Message", nil];
    }
    return _tellAFriendActionSheet;
}


#pragma mark - Instance Methods
#pragma mark Actions

// -------------------------------------------------------------------------------
//  showMailPicker:
//  Action for the Compose Mail button.
// -------------------------------------------------------------------------------
- (void)showMailPicker:(NSString *)message subject:(NSString *)subject toRecipients:(NSArray *)recipients
{
    // You must check that the current device can send email messages before you
    // attempt to create an instance of MFMailComposeViewController.  If the
    // device can not send email messages,
    // [[MFMailComposeViewController alloc] init] will return nil.  Your app
    // will crash when it calls -presentViewController:animated:completion: with
    // a nil view controller.
    if ([MFMailComposeViewController canSendMail]) {
        // The device can send email.
        [self displayMailComposerSheet:message subject:subject toRecipients:recipients];
        
    } else {
        // The device can not send email.
        // This would be a good place to show a message saying device can't
        // send mail.
    }
}

// -------------------------------------------------------------------------------
//  showSMSPicker:
//  Action for the Compose SMS button.
// -------------------------------------------------------------------------------
- (IBAction)showSMSPicker
{
    // You must check that the current device can send SMS messages before you
    // attempt to create an instance of MFMessageComposeViewController.  If the
    // device can not send SMS messages,
    // [[MFMessageComposeViewController alloc] init] will return nil.  Your app
    // will crash when it calls -presentViewController:animated:completion: with
    // a nil view controller.
    if ([MFMessageComposeViewController canSendText]) {
        // The device can send email.
        [self displaySMSComposerSheet];
        
    } else {
        // The device can not send email.
        // This would be a good place to show a message saying device can't
        // send SMS.
    }
}

#pragma mark Compose Mail/SMS

// -------------------------------------------------------------------------------
//  displayMailComposerSheet
//  Displays an email composition interface inside the application.
//  Populates all the Mail fields.
// -------------------------------------------------------------------------------
- (void)displayMailComposerSheet:(NSString *)message subject:(NSString *)subject toRecipients:(NSArray *)recipients
{
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    
    [picker setSubject:subject];
    
    // Set up recipients
    NSArray *toRecipients = (recipients != nil) ? recipients : @[];
    NSArray *ccRecipients = @[];
    NSArray *bccRecipients = @[];
    
    [picker setToRecipients:toRecipients];
    [picker setCcRecipients:ccRecipients];
    [picker setBccRecipients:bccRecipients];
    
    // Fill out the email body text
    [picker setMessageBody:message isHTML:NO];
    
    [self presentViewController:picker animated:YES completion:NULL];
}

// -------------------------------------------------------------------------------
//  displaySMSComposerSheet
//  Displays an SMS composition interface inside the application.
// -------------------------------------------------------------------------------
- (void)displaySMSComposerSheet
{
    MFMessageComposeViewController *picker = [[MFMessageComposeViewController alloc] init];
    picker.messageComposeDelegate = self;
    
    // You can specify one or more preconfigured recipients.  The user has
    // the option to remove or add recipients from the message composer view
    // controller.
    /* picker.recipients = @[@"Phone number here"]; */
    
    // You can specify the initial message text that will appear in the message
    // composer view controller.
    picker.body = kTellAFriendMessageBody;
    
    [self presentViewController:picker animated:YES completion:NULL];
}


#pragma mark - MFMailComposeViewControllerDelegate

// -------------------------------------------------------------------------------
//  mailComposeController:didFinishWithResult:
//  Dismisses the email composition interface when users tap Cancel or Send.
//  Proceeds to update the message field with the result of the operation.
// -------------------------------------------------------------------------------
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    // A good place to notify users about errors associated with the interface
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - MFMessageComposeViewControllerDelegate
// -------------------------------------------------------------------------------
//  messageComposeViewController:didFinishWithResult:
//  Dismisses the message composition interface when users tap Cancel or Send.
//  Proceeds to update the feedback message field with the result of the
//  operation.
// -------------------------------------------------------------------------------
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result
{
    // A good place to notify users about errors associated with the interface
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // get the selected cell
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
    // Action to perform depends on clicked cell
    if (selectedCell == self.tellAFriendCell) {
        // tella  friend
        [self.tellAFriendActionSheet showInView:self.tableView];
        
    } else if (selectedCell == self.contactSupportCell) {
        // contact support
        [self showMailPicker:kContactSupportMailBody subject:kContactSupportMailSubject toRecipients:@[kContactSupportMailAddress]];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet == self.tellAFriendActionSheet) {
        // tell a friend about Retrac either via Mail or SMS.
        switch (buttonIndex) {
            case kTellAFriendMailButtonIndex:
                [self showMailPicker:kTellAFriendMailBody subject:kTellAFriendMailSubject toRecipients:nil];
                break;
                
            case kTellAFriendMessageButtonIndex:
                [self showSMSPicker];
                break;
                
            default:
                break;
        }
    }
}



@end
