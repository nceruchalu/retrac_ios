//
//  RTCPlacesCDTVC.m
//  Retrac
//
//  Created by Nnoduka Eruchalu on 8/1/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "RTCPlacesCDTVC.h"
#import "RTCAddPlaceViewController.h"
#import "RTCPlaceDirectionsViewController.h"
#import "RTCPlaceDetailsViewController.h"
#import "RTCPlace+Location.h"
#import "RTCPlace+MKAnnotation.h"
#import "RTCModelManager.h"
#import "RTCPlaceTableViewCell.h"

@interface RTCPlacesCDTVC ()

// need this property to get a handle to the database
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation RTCPlacesCDTVC

#pragma mark - Properties
/**
 * This view controller cannot function until the managed object context is set
 */
- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    [self setupFetchedResultsController];
}


#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // setup the managedObjectContext @property
    self.managedObjectContext = [RTCModelManager sharedManager].managedObjectContext;
    
    // register observers
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
    
    // end editing as view is going away
    [self setEditing:NO];

}


#pragma mark - Instance Methods
#pragma mark Private
/**
 * Hook up fetchedResultsController property to any place request
 *
 * Creates an NSFetchRequest for RTCPlaces sorted by descending creationDate.
 * This NSFetchRequest is used to build  our NSFetchedResultsController @property
 * inherited from CoreDataTableViewController.
 *
 * Assumption: This method is only called when self.managedObjectContext has been
 *   configured.
 */
- (void)setupFetchedResultsController
{
    if (self.managedObjectContext) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"RTCPlace"];
        
        // fetch all places so no predicate
        
        NSSortDescriptor *creationDateSort = [NSSortDescriptor sortDescriptorWithKey:@"creationDate"
                                                                           ascending:NO];
        
        [request setSortDescriptors:@[creationDateSort]];
        [request setFetchBatchSize:20];
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                            managedObjectContext:self. managedObjectContext sectionNameKeyPath:nil
                                                                                       cacheName:nil];
    } else {
        self.fetchedResultsController = nil;
    }

}


#pragma mark Notification Observer Methods

/**
 * ManagedObjectContext now available from RTCModelManager so update local copy
 */
- (void)managedObjectContextReady:(NSNotification *)aNotification
{
    self.managedObjectContext = [RTCModelManager sharedManager].managedObjectContext;
}


#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Place Cell"; // get the cell
    RTCPlaceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    RTCPlace *place = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Configure the cell with data from the managed object
    cell.nameLabel.text = place.title;
    cell.creationDateLabel.text = [place timeSinceCreation];
    
    return cell;
}

#pragma mark Deleting rows
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // if the table is asking to commit a delete command, delete the place
        RTCPlace *place = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [place.managedObjectContext deleteObject:place];
    }
}

#pragma mark - UITableViewDelegate
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


#pragma mark - Navigation
- (void)prepareViewController:(id)vc
                     forSegue:(NSString *)segueIdentifier
                fromIndexPath:(NSIndexPath *)indexPath
{
    if ([vc isKindOfClass:[RTCAddPlaceViewController class]]) {
        // show the VC to add a new place
        if ([segueIdentifier isEqualToString:@"presentAddPlace"]) {
            // ideally would prepare VC here, but there's nothing to do really
            // as this VC handles itself
        }
        
    } else if ([vc isKindOfClass:[RTCPlaceDirectionsViewController class]]) {
        // show the VC to load directions to a place
        if (![segueIdentifier length] || [segueIdentifier isEqualToString:@"showPlaceDirections"]) {
            // prepare vc
            RTCPlace *place = [self.fetchedResultsController objectAtIndexPath:indexPath];
            RTCPlaceDirectionsViewController *directionsVC = (RTCPlaceDirectionsViewController *)vc;
            directionsVC.destinationPlace = place;
        }
        
    } else if  ([vc isKindOfClass:[RTCPlaceDetailsViewController class]]) {
        // show the VC to show a place's details
        if (![segueIdentifier length] || [segueIdentifier isEqualToString:@"showPlaceDetails"]) {
            // prepare vc
            RTCPlace *place = [self.fetchedResultsController objectAtIndexPath:indexPath];
            RTCPlaceDetailsViewController *detailsVC = (RTCPlaceDetailsViewController *)vc;
            detailsVC.place = place;
        }
    }
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = nil;
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        indexPath = [self.tableView indexPathForCell:sender];
    }
    
    // account for the fact that the destination VC could be modally presented
    // as the root view controller of a Navigation View Controller
    id destinationVC = segue.destinationViewController;
    if ([destinationVC isKindOfClass:[UINavigationController class]]) {
        destinationVC = [((UINavigationController *)destinationVC).viewControllers firstObject];
    }
    
    [self prepareViewController:destinationVC
                       forSegue:segue.identifier
                  fromIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id detailVC = [self.splitViewController.viewControllers lastObject];
    if ([detailVC isKindOfClass:[UINavigationController class]]) {
        detailVC = [((UINavigationController *)detailVC).viewControllers firstObject];
        [self prepareViewController:detailVC
                           forSegue:nil
                      fromIndexPath:indexPath];
    }
}



#pragma mark Modal Unwinding
- (IBAction)addedPlace:(UIStoryboardSegue *)segue
{
    if ([segue.sourceViewController isKindOfClass:[RTCLocationViewController class]]) {
        RTCAddPlaceViewController *addPlaceVC = (RTCAddPlaceViewController *)segue.sourceViewController;
        RTCPlace *createdPlace = addPlaceVC.createdPlace;
        if (createdPlace) {
            // if a place was created do something interesting here.
        }
    }
}

@end
