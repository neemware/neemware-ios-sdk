//
//  NWInboxTableViewController.h
//  NeemwareSDK
//
//  Created by Erik Stromlund (neemware) on 8/7/12.
//  Copyright (c) 2012 Neemware, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NWInboxTableViewControllerDelegate <NSObject>

@required
// Called when the 'Close' button is pressed
// You must dismiss the inbox properly
// i.e. in your UIViewController that is the delegate, you will
// want to call [self dismissModalViewController];
// or [self dismissViewControllerAnimated:completion:]
// or whatever is appropriate in your code
-(void)dismissInbox;

@end

@interface NWInboxTableViewController : UITableViewController
// IMPORTANT: This class must be placed inside a UINavigationController for full functionality

// Receive state notifications for the inbox
// Currently, the only implemented method is dismissInbox
@property (nonatomic, assign) id <NWInboxTableViewControllerDelegate> delegate;
@end