//
//  NWAppDelegate.h
//  NeemwareSDK
//
//  Created by work on 8/7/12.
//  Copyright (c) 2012 Neemware, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface NWAppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UITabBarController *tbc;

@property (strong, nonatomic) CLLocationManager *locationManager;

@end
