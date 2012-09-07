//
//  NWAppDelegate.m
//  NeemwareSDK
//
//  Created by work on 8/7/12.
//  Copyright (c) 2012 Neemware, Inc. All rights reserved.
//

#import "NWAppDelegate.h"
#import <Neemware/Neemware.h>
#import "TestMainViewController.h"
#import <CoreLocation/CoreLocation.h>

@implementation NWAppDelegate
@synthesize tbc;
@synthesize locationManager;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.

#warning Please be sure to set this API key to your own - get one at http://app.neemware.com
    [Neemware loadWithApiKey:@"212906882c9db5e0c259b0d47517e258"];
    
    [self startFindingLocation];
    
    // Register for Neemware update notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(neemwareUpdated) name:@"kNWInboxDataChangedNotification" object:nil];
    
    TestMainViewController *testVC = [[TestMainViewController alloc] init];
    testVC.tabBarItem.title = @"The Page";
    
    tbc = [[UITabBarController alloc] init];
    [tbc setViewControllers:[NSArray arrayWithObject:testVC]];
    self.window.rootViewController = tbc;
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)neemwareUpdated
{
    [[[[tbc viewControllers] objectAtIndex:0] tabBarItem] setBadgeValue:[Neemware inboxUnreadCount]];
}

- (void)startFindingLocation
{
    // Create the location manager if this object does not
    // already have one.
    if (locationManager == nil)
        locationManager = [[CLLocationManager alloc] init];
    
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    
    // Set a movement threshold for new events.
    locationManager.distanceFilter = 500;
    
    [locationManager startUpdatingLocation];
}

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    // If it's a relatively recent event, turn off updates to save power
    NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0)
    {
        NSLog(@"latitude %+.6f, longitude %+.6f\n",
              newLocation.coordinate.latitude,
              newLocation.coordinate.longitude);
        
        [Neemware setUserLocationWithLatitude:newLocation.coordinate.latitude andLongitude:newLocation.coordinate.longitude];
    }
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
