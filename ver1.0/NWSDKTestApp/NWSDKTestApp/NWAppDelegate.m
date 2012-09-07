//
//  NWAppDelegate.m
//  NeemwareSDK
//
//  Created by Erik Stromlund on 8/7/12.
//  Copyright (c) 2012 Neemware, Inc. All rights reserved.
//

#import "NWAppDelegate.h"
#import <Neemware/Neemware.h>
#import "TestMainViewController.h"
#import "NWTestSecondViewController.h"

@implementation NWAppDelegate
@synthesize tbc;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.

#warning Please be sure to set this API key to your own - get one at http://app.neemware.com
    [Neemware loadWithApiKey:@"212906882c9db5e0c259b0d47517e258"];
    
    // Register for Neemware update notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(neemwareUpdated) name:@"kNWInboxDataDidLoadNotification" object:nil];
    
    TestMainViewController *testVC = [[TestMainViewController alloc] init];
    testVC.tabBarItem.title = @"Inbox";
    
    NWTestSecondViewController *testVC2 = [[NWTestSecondViewController alloc] init];
    testVC2.tabBarItem.title = @"Home";
    
    tbc = [[UITabBarController alloc] init];
    [tbc setViewControllers:[NSArray arrayWithObjects:testVC, testVC2, nil]];
    self.window.rootViewController = tbc;
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)neemwareUpdated
{
    [[[[tbc viewControllers] objectAtIndex:1] tabBarItem] setBadgeValue:[Neemware inboxUnreadCount]];
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
