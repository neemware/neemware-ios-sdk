//
//  Neemware.h
//  NeemwareSDK
//
//  Created by Erik Stromlund on 8/7/12.
//  Copyright (c) 2012 Neemware, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Neemware : NSObject {
    NSString*       _apiKey;
    NSDictionary*   _locationData;
}

/**
 * This method must be called before using the Neemware SDK
 * sing key/secret from Neemware website
 * This method should only be called once, typically in application:didFinishLaunchingWithOptions
 * This method must be called before any other Neemware methods are called
 */
+ (void)loadWithApiKey:(NSString *)apiKey;

/**
 * Use these methods to set (optional) custom properties
 **/

// Call this method whenever new location information is obtained
// For example, call this method in your CLLocationManagerDelegate's didUpdateToLocation:FromLocation:
// and that location will be sent to Neemware on subsequent calls or updates
+ (void)setUserLocationWithLatitude:(double)lat andLongitude:(double)lon;

/**
 * Accessors
 */
+ (NSString *)      apiKey;
+ (NSString *)      udid;
+ (NSDictionary *)  location;
+ (NSString *)      latitude;
+ (NSString *)      longitude;
+ (NSString *)      version;


////////////////////////////////////////////////////////////

// Inbox-related methods
//
//  Accessors
//
// Call this method to get the current number of unread things in your Message Center inbox
+ (NSString *)      inboxUnreadCount;

//  Methods
// Wire this method up to anything you want and it will display the Message Center
// Typical usage within a UIViewController will be [Neemware displayInboxFrom:self];
+ (void)            displayInboxFrom:(UIViewController *)vc;

// For more options, or for displaying on an iPad
+ (void)            displayInboxFrom:(UIViewController *)vc
                        withModalTransitionStyle:(UIModalTransitionStyle)ts
                            modalPresentationStyle:(UIModalPresentationStyle)ps
                                animation:(BOOL)animated;

////////////////////////////////////////////////////////////

// For displaying the banner and subsequent UIViewController
//
//  Methods
//
// Call this method in the viewDidAppear method for each UIViewController that you
// would like to be available to display banner messages.  Banners will only be displayed
// when you select 'Display in Banner' in the Neemware Web Dashboard so it is up to you when
// it is displayed or not
+ (void)showBannerInViewController:(UIViewController *)vController;

// When the banner is tapped, a UIViewController will be presented
// This optional method (**recommended for iPads**) provides control over how that
// UIViewController is presented (delay, however, refers to the delay in displaying the banner itself)
+ (void)showBannerInViewController:(UIViewController *)vController
                            withDelay:(NSInteger)delay
                                modalTransitionStyle:(UIModalTransitionStyle)ts
                                    modalPresentationStyle:(UIModalPresentationStyle)ps
                                        animation:(BOOL)animated;
@end
