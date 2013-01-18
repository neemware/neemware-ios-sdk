//
//  NWFeedbackViewController.h
//
//  Created by Puru Choudhary on 12/13/11.
//  Modified by Erik Stromlund on 12/15/2012
//  Copyright (c) 2013 Neemware. All rights reserved.
//

#import <UIKit/UIKit.h>
@class NWFeedbackViewController;

@protocol NWFeedbackFormDelegate <NSObject>
@optional
- (void)dismissFeedbackForm:(NWFeedbackViewController *)feedbackForm;
@end

@interface NWFeedbackViewController : UIViewController {
}

/**
 * IMPORTANT: NWFeedbackViewController must be presented in a UINavigationController
 * A rightBarButtonItem (a submit button) will be provided
 *
 */

/**
 * Set the user's email address (optional)
 *
 * If no email address is set before presenting the UIViewController,
 * then a field will be provided for the user to enter an email
 */
@property (nonatomic, copy) NSString *userEmailAddress;  // Optional

/**
 * Delegate that receives the notifications about state changes
 *
 */
@property (nonatomic, assign) id <NWFeedbackFormDelegate> delegate;

@end
