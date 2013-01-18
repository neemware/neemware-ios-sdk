//
//  Neemware.h
//  NeemwareSDK
//
//  Created by Erik Stromlund on 8/7/12.
//  Copyright (c) 2013 Neemware, Inc. All rights reserved.
//
//
// ************* Detailed implementation instructions are at Neemware.com **********
//

#import <Foundation/Foundation.h>

@interface Neemware : NSObject

/** Quick Start Guide:
 * 1. Import "Neemware.h"
 * 2. Call [Neemware loadWithApiKey:@"YOUR API KEY"] in application:didFinishLaunchingWithOptions:
 * 3. Call [Neemware showBannerInViewController:**viewController**] in viewDidAppear: where you would like banners to display
 * 4. Call [Neemware displayInboxFrom:self] in any viewController method (i.e. an IBAction method wired to a button)
 * 5. Call [Neemware displayFeedbackFormIn:self] in any viewController method (i.e. an IBAction method wired to a button)
 *
 */

/*
 * This method must be called before using the Neemware SDK, typically
 * in application:didFinishLaunchingWithOptions.
 * This method must be called before any other Neemware methods are called
 * Get your API key at http://www.neemware.com
 */
+ (void)loadWithApiKey:(NSString *)apiKey;

/*
 * Enable or disable loading new data when app becomes active
 * Defaults to YES
 */
+ (void)setRefreshDataOnLoad:(BOOL)refresh;

/*
 * Use this method to manually trigger an update of the Neemware data
 * For example, use this to trigger an update after a push notification is received
 */
+ (void)refreshData;

/*
 * Use these methods to set (optional) custom properties
 */

/* Call this method whenever new location information is obtained
 * For example, call this method in your CLLocationManagerDelegate's didUpdateToLocation:FromLocation:
 * and that location will be sent to Neemware on subsequent calls or updates
 */
+ (void)setUserLocationWithLatitude:(double)lat andLongitude:(double)lon;

/*
 * Customize the color of the title bar and title bar text
 */
+ (void)setTitleBarColor:(UIColor *)barColor;
+ (void)setTitleBarTextColor:(UIColor *)textColor;

////////////////////////////////////////////////////////////

// Inbox-related methods
//
//  Accessors
//
// Call this method to get the current number of unread things in your Message Center inbox
// This method will return nil rather than 0 so that the value may be directly passed to a badge
+ (NSString *)      inboxUnreadCount;

// Methods
//
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

////////////////////////////////////////////////////////////

// For displaying the feedback from
//
//  Methods
//
// Wire this method up to anything you want and it will display the Message Center
// Typical usage within a UIViewController will be [Neemware displayFeedbackFromIn:self];
+ (void)       displayFeedbackFormIn:(UIViewController *)vc;

// For more options, or for displaying on an iPad
+ (void)       displayFeedbackFormIn:(UIViewController *)vc
            withModalTransitionStyle:(UIModalTransitionStyle)ts
              modalPresentationStyle:(UIModalPresentationStyle)ps
                           animation:(BOOL)animated;



////////////////////////////////////////////////////////////

// For tracking in-app events
//
//  Methods
//
// Call this method to log an event within your app.  After an event is logged,
// you can use that event to target any content (i.e. messages, questions, or promotions)
// from the Neemware web dashboard

+ (void)logEvent:(NSString *)eventName;

////////////////////////////////////////////////////////////

// For enabling push notifications
//
// Methods
//
// Put this method in applicationDidRegisterForPushNotifications, and pass the |deviceToken|

+ (void)storeDeviceToken:(NSData *)theDeviceToken;

////////////////////////////////////////////////////////////
/**
 * Accessors
 */
+ (NSString *)      apiKey;
+ (NSString *)      udid;
+ (NSDictionary *)  location;
+ (NSString *)      latitude;
+ (NSString *)      longitude;
+ (NSString *)      version;
+ (BOOL)            refreshDataOnLoad;
+ (UIColor *)       titleBarColor;
+ (UIColor *)       titleBarTextColor;
@end
