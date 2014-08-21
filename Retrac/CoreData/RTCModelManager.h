//
//  RTCModelManager.h
//  Retrac
//
//  Created by Nnoduka Eruchalu on 7/31/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * RTCModelManager is a singleton class that ensures we have just one instance
 * of UIManagedDocument throughout this application for each actual document.
 * This way all changes will always be seen by all readers and writers of the
 * document.
 */
@interface RTCModelManager : NSObject

#pragma mark -  Properties

/**
 * Database handle for app's Core Data storage facility
 */
@property (strong, nonatomic, readonly) NSManagedObjectContext *managedObjectContext;


#pragma mark - Class Methods
/**
 * Single instance manager.
 * It creates the instance if this hasn't been done or simply returns it.
 *
 * @return An initialized RTCModelManager object.
 */
+ (instancetype)sharedManager;


#pragma mark - Instance Methods

/**
 * Setup document for app. This sets up the internal UIManagedDocument and its
 * associated managedObjectContext.
 * This will close a previously opened document that is still open
 *
 * @param documentIsReady
 *      A block object to be executed when the document and managed object context
 *      are setup. This block has no return value and takes no arguments.
 */
- (void)setupPlacesDocument:(void (^)())documentIsReady;


/**
 * Asynchronously save and close UIManagedDocument.
 *
 * @param documentIsClosed
 *      block to be called when document is closed successfully.
 */
- (void)closePlacesDocument:(void (^)())documentIsClosed;


/**
 * Force an asynchronous manual save of the usually auto-saved UIManagedDocument.
 *
 * @param documentIsSaved
 *      block to be called when document is saved.
 */
- (void)savePlacesDocument:(void (^)())documentIsSaved;

@end
