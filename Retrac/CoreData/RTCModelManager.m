//
//  RTCModelManager.m
//  Retrac
//
//  Created by Nnoduka Eruchalu on 7/31/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "RTCModelManager.h"
#import <CoreData/CoreData.h>

// Constants
// Relative address of UIManagedDocument
static NSString *const kPlacesDocumentPath = @"PlacesDocument";

@interface RTCModelManager ()

// want all properties to be readwrite internally
@property (strong, nonatomic, readwrite) NSManagedObjectContext *managedObjectContext;

/**
 * This app does not have user authentication, so we will have just one document
 * shared by all phone users.
 */
@property (strong, nonatomic) UIManagedDocument *placesDocument;

@end

@implementation RTCModelManager

#pragma mark - Properties
- (void)setPlacesDocument:(UIManagedDocument *)placesDocument
{
    _placesDocument = placesDocument;
    self.managedObjectContext = nil;
}

#pragma mark - Class methods
#pragma mark Public
// Declare a static variable, which is an instance of this class
// It is initialized once and only once in a thread-safe manner by using
//   Grand Central Dispatch (GCD)
+ (instancetype)sharedManager
{
    static RTCModelManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initPrivate];
    });
    return sharedInstance;
}


#pragma mark - Initialization
// ideally we would make the designated initializer of the superclass call
//   the new designated initializer, but that doesn't make sense in this case.
// if a programmer calls [RTCModelManager alloc] init], let them know the error
//   of their ways.
- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use + [RTCModelManager sharedManager]"
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

#pragma mark - Instance Methods
#pragma mark Public
- (void)setupPlacesDocument:(void (^)())documentIsReady
{
    // if a document is already open close it out before setting up document
    if (self.placesDocument) {
        [self closePlacesDocument:^{
            [self setupNewPlacesDocument:documentIsReady];
        }];
        
    } else {
        [self setupNewPlacesDocument:documentIsReady];
    }
}


/**
 * Asynchronously save and close UIManagedDocument.
 *
 * @param documentIsClosed
 *      block to be called when document is closed successfully.
 */
- (void)closePlacesDocument:(void (^)())documentIsClosed
{
    [self.placesDocument closeWithCompletionHandler:^(BOOL success) {
        // it would be ideal to check for success first, but if this fails
        // it's game over anyways.
        // we indicate document closure by clearing out placesDocument
        self.placesDocument = nil;
        
        // notify all listeners that this managedObjectContext is no longer valid
        [[NSNotificationCenter defaultCenter] postNotificationName:kRTCMOCDeletedNotification
                                                            object:self];
        if (documentIsClosed) documentIsClosed();
    }];
}


/**
 * Force an asynchronous manual save of the usually auto-saved UIManagedDocument.
 *
 * @param documentIsSaved
 *      block to be called when document is saved.
 */
- (void)savePlacesDocument:(void (^)())documentIsSaved
{
    [self.placesDocument saveToURL:self.placesDocument.fileURL
                forSaveOperation:UIDocumentSaveForOverwriting
               completionHandler:^(BOOL success) {
                   if (success) {
                       if (documentIsSaved) documentIsSaved();
                   }
               }
     ];
}


#pragma mark - Private
/**
 * Setup new places document . This sets up the internal UIManagedDocument and 
 * its associated managedObjectContext
 *
 * This is different from the public method setupDocument: in that it doesn't 
 * close a previously opened document.
 *
 * @param documentIsReady
 *      A block object to be executed when the document and managed object context
 *      are setup. This block has no return value and takes no arguments.
 *
 * @warning You probably shouldn't call this without first closing the document.
 */
- (void)setupNewPlacesDocument:(void (^)())documentIsReady
{
    // setup userDocument @property as a document in the application's document directory
    NSURL *docURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    
    docURL = [docURL URLByAppendingPathComponent:kPlacesDocumentPath];
    self.placesDocument = [[UIManagedDocument alloc] initWithFileURL:docURL];
    
    // support automatic migration
    // see documentation of NSPersistentStoreCoordinator for details
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption  : @(YES),
                              NSInferMappingModelAutomaticallyOption        : @(YES)};
    self.placesDocument.persistentStoreOptions = options;
    
    // use placesDocument to setup managedObjectContext @property
    [self usePlacesDocument:^{
        // notify all listeners that this managedObjectContext is now setup
        [[NSNotificationCenter defaultCenter] postNotificationName:kRTCMOCAvailableNotification
                                                            object:self];
        if (documentIsReady) documentIsReady();
    }];
}

/**
 * Either creates, opens or just uses the placesDocument.
 * Creating and opening are async, so in the completion handler we set our model
 *   (managedObjectContext).
 * This sets up the managedObjectContext property if it isn't already setup
 *   then it calls the ^(void)documentIsReady block.
 *
 * @param documentIsReady
 *      block to be called when document is ready and managedObjectContext
 *      property is setup.
 */
- (void)usePlacesDocument:(void (^)())documentIsReady
{
    // access the shared instance of the document
    NSURL *url = self.placesDocument.fileURL;
    UIManagedDocument *document = self.placesDocument;
    
    // must first open/create the document to use it so check to see if it
    // exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        // if document doesn't exist create it
        [document saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            if (success) {
                self.managedObjectContext = document.managedObjectContext;
                // just created this document so this would be a good time to call
                // methods to populate the data. However there is no need for
                // that in this case.
                if (documentIsReady) documentIsReady();
            }
        }];
        
    } else if (document.documentState == UIDocumentStateClosed) {
        // if document exists but is closed, open it
        [document openWithCompletionHandler:^(BOOL success) {
            if (success) {
                self.managedObjectContext = document.managedObjectContext;
                // if already open, no need to attempt populating the data.
                if (documentIsReady) documentIsReady();
            }
        }];
        
    } else {
        // if document is already open try to use it
        self.managedObjectContext = document.managedObjectContext;
        // again already open, so no need to attempt populating the data.
        if (documentIsReady) documentIsReady();
    }
}


@end
