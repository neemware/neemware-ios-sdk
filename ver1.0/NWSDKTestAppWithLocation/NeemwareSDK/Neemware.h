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
    NSString*       _userID;
    NSDictionary*   _locationData;
    NSDictionary*   _customUserInformation;
    NSInteger       _updateInterval;
}

/**
 * This init method must be called before using Neemware SDK using key/secret from Neemware website
 * This method should only be called once, at the beginning of the user's session
 * If called again, all user data will be reset
 */
+ (void)loadWithApiKey:(NSString *)apiKey;

/**
 * Use these methods to set (optional) custom properties
 **/

// Call this method whenever new location information is obtained and we will
// include it with our results
+ (void)setUserLocationWithLatitude:(double)lat andLongitude:(double)lon;

// This is how often Neemware checks for new messages
//+ (void)setUpdateInterval:(NSInteger)updateInterval;

// Associate users in the Neemware system with your own numbering
//+ (void)setUserID:(NSString *)uid;

// Set custom user information such as email, twitter handle, age, gender...whatever you want
// Please make sure to send only NSStrings within the dictionary
+ (void)setCustomUserInformation:(NSDictionary *)dict;

/**
 * Accessors
 */
+ (NSString *)      apiKey;
//+ (NSString *)      userID;
+ (NSString *)      udid;
+ (NSDictionary *)  location;
+ (NSString *)      latitude;
+ (NSString *)      longitude;
+ (NSString *)      version;
+ (NSDictionary *)  customUserInformation;


////////////////////////////////////////////////////////////

// This section for inbox-specific things
//
//  Accessors
//
// Call this method to get the current number of unread things in your Message Center inbox
+ (NSString *)      inboxUnreadCount;

//  Methods
// Wire this method up to anything you want and it will display the Message Center
// Typical usage within a UIViewController will be [Neemware displayInboxFrom:self];
+ (void)            displayInboxFrom:(UIViewController *)vc;

////////////////////////////////////////////////////////////

// This section for banner-specific things
//
//  Methods
//
// Call this method in the viewDidAppear method for each UIViewController that you
// would like to be available to display banner messages.  Banners will only be displayed
// when you select 'Display in Banner' in the Neemware Web Dashboard so it is up to you when
// it is displayed or not
+(void)showBannerInViewController:(UIViewController *)vController;

@end
