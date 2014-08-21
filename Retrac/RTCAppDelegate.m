//
//  RTCAppDelegate.m
//  Retrac
//
//  Created by Nnoduka Eruchalu on 7/30/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "RTCAppDelegate.h"
#import "RTCModelManager.h"

// Tab Bar item positions
static const NSUInteger kTabBarIndexPlaces      = 0;
static const NSUInteger kTabBarIndexLocation    = 1;
static const NSUInteger kTabBarIndexAbout       = 2;

@implementation RTCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    // Set up managed object context
    [[RTCModelManager sharedManager] setupPlacesDocument:nil];
    
    // set appearance of views
    [[UITabBar appearance] setTintColor:kRTCThemeColor];
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setFont:[UIFont fontWithName:kRTCFontNameBold size:14.0]];
    
    // Setup tabBar icons
    UITabBarController *tabBarController = (UITabBarController *)(self.window.rootViewController);
    UITabBar *tabBar = tabBarController.tabBar;
    
    UITabBarItem *tabBarItemPlaces = [tabBar.items objectAtIndex:kTabBarIndexPlaces];
    tabBarItemPlaces.selectedImage = [UIImage imageNamed:@"globe-full"];
    
    UITabBarItem *tabBarItemLocation = [tabBar.items objectAtIndex:kTabBarIndexLocation];
    tabBarItemLocation.selectedImage = [UIImage imageNamed:@"map-full"];
    
    UITabBarItem *tabBarItemAbout = [tabBar.items objectAtIndex:kTabBarIndexAbout];
    tabBarItemAbout.selectedImage = [UIImage imageNamed:@"info-full"];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
