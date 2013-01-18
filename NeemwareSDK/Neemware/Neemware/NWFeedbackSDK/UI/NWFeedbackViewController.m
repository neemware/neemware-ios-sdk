//
//  NWFeedbackViewController.m
//
//  Created by Puru Choudhary on 12/13/11.
//  Modified by Erik Stromlund on 12/15/2012
//  Copyright (c) 2013 Neemware. All rights reserved.
//

#import "NWFeedbackViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "NWFeedbackConstants.h"
#import "NWFeedback.h"
#import "NWConnection.h"
#import "NW_MBProgressHUD.h"
#import "SSTextView.h"
#import "Neemware.h"

@interface NWFeedbackViewController () <UITextViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, NWConnectionDelegate> 

// UI
@property (nonatomic, strong) IBOutlet SSTextView  *descriptionTextView;  // SSTextView adds placeholder support
@property (nonatomic, strong) IBOutlet UITextField *emailTextField;
@property (nonatomic, strong) NW_MBProgressHUD     *progressHUD;
@property (nonatomic, strong) IBOutlet UIView      *smileyButtonsContainer;

// Core
@property (nonatomic, strong) NWConnection *feedbackConnection;

// Actions
- (IBAction)smileyButtonPressed:(id)sender;
- (IBAction)sendFeedbackPressed:(id)sender;
@end

@implementation NWFeedbackViewController

# pragma mark - Accessors
// Public
@synthesize delegate             = _delegate;

// UI
@synthesize descriptionTextView;
@synthesize emailTextField;
@synthesize progressHUD;
@synthesize smileyButtonsContainer;

// Core
@synthesize feedbackConnection;

# pragma mark - Setup and cleanup
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)cleanup
{
    [self.progressHUD hide:YES];
    self.progressHUD = nil;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Make sure we are in a nav controller
    assert([self.parentViewController isKindOfClass:[UINavigationController class]]);
    
    // Title
    self.title = @"Feedback";
    
    UIBarButtonItem *submitButton = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleDone target:self action:@selector(sendFeedbackPressed:)];
    [submitButton setEnabled:NO];
    [submitButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[Neemware titleBarTextColor], UITextAttributeTextColor, nil] forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = submitButton;
    submitButton = nil;
    
    // Set color
    [self.navigationController.navigationBar setTintColor:[Neemware titleBarColor]];
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[Neemware titleBarTextColor], UITextAttributeTextColor, nil]];
    
    // Progress HUD
    [self.view addSubview:self.progressHUD];
    
    // Description field
    self.descriptionTextView.backgroundColor = [UIColor whiteColor];
    self.descriptionTextView.delegate = self;
    self.descriptionTextView.placeholder = @"How can we help you?";
    
    // Email field
    
    // First, userEmailAddress may have been set by developer
    // If it wasn't, check if email is stored in NSUserDefaults
    if (!self.userEmailAddress)
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *previousEmail = [defaults objectForKey:@"NWFeedbackEmail"];
        if (previousEmail) {
            self.userEmailAddress = previousEmail;
        }
    }
    
    // If we have the email, then hide the email form
    // If we don't, then configure the email form
    if (self.userEmailAddress && ![self.userEmailAddress isEqualToString:@""])
    {
        // Because there is no longer an email field, extend the text field down further
        self.descriptionTextView.frame = CGRectUnion(self.descriptionTextView.frame, self.emailTextField.frame);
        
        // Remove the email field from the view
        [self.emailTextField removeFromSuperview];
        self.emailTextField = nil;
    } else
    {
        self.emailTextField.backgroundColor = [UIColor whiteColor];
        self.emailTextField.returnKeyType = UIReturnKeyDone;
        self.emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
        self.emailTextField.delegate = self;
    }
    
    // Add bottom border to description field
    CALayer *emailTopBorder = [[CAGradientLayer alloc] init];
    emailTopBorder.frame = CGRectMake(0, 0, self.emailTextField.frame.size.width, 1);
    emailTopBorder.backgroundColor = [UIColor colorWithRed:(240.0/255.0) green:(240.0/255.0) blue:(240.0/255.0) alpha:1.0].CGColor;
    [self.emailTextField.layer addSublayer:emailTopBorder];
    emailTopBorder = nil;
    
    [self.smileyButtonsContainer setBackgroundColor:[UIColor colorWithRed:(250.0/255.0) green:(250.0/255.0) blue:(250.0/255.0) alpha:1.0]];
    
    // Add shadow to top of smiley container
    CALayer *smileyContainerTopBorder = [[CAGradientLayer alloc] init];
    CGRect sCFrame = CGRectMake(0, 0, self.smileyButtonsContainer.frame.size.width, 1);
    smileyContainerTopBorder.frame = sCFrame;
    smileyContainerTopBorder.backgroundColor = [UIColor colorWithRed:(240.0/255.0) green:(240.0/255.0) blue:(240.0/255.0) alpha:1.0].CGColor;
    [self.smileyButtonsContainer.layer addSublayer:smileyContainerTopBorder];
    smileyContainerTopBorder = nil;
    
    // Bring up the keyboard
    [self.descriptionTextView becomeFirstResponder];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.descriptionTextView = nil;
    self.emailTextField = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

# pragma mark - UITextFieldDelegate protocol methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    if ([textField isEqual:self.emailTextField]) {
        return (newLength > 100) ? NO : YES;
    }
    return YES;
}

# pragma mark - UITextViewDelegate protocol methods

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    // Enable/disable the send button
    if (self.descriptionTextView.text.length < 2)
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    else
    {
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
    }
    
    NSUInteger newLength = [textView.text length] + [text length] - range.length;
    if ([textView isEqual:self.emailTextField]) {
        return (newLength > 1200) ? NO : YES;
    }
    return YES;
}

# pragma mark - Smiley handling
- (IBAction)smileyButtonPressed:(id)sender
{
    // Unselect/unhighlight all the buttons
    for (UIView *subview in self.smileyButtonsContainer.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;
            button.selected = NO;
            button.highlighted = NO;
        }
    }
    
    // Select/highlight the tapped button
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        button.selected = YES;
        button.highlighted = YES;
    }
}

# pragma mark - Send Feedback
- (void)sendFeedbackPressed:(id)sender
{
    NWDLog(@"Send feedback...");
    NSString *ratingString;
    NSNumber *rating = nil;
    
    // Get the rating
    for (id subview in self.smileyButtonsContainer.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
                UIButton *button = (UIButton *)subview;
                if (button.selected) {
                    ratingString = button.titleLabel.text;
                    if ([ratingString isEqualToString:@"1"]) {
                        rating = [NSNumber numberWithInt:1];
                    }
                    else if ([ratingString isEqualToString:@"3"]) {
                        rating = [NSNumber numberWithInt:3];
                    }
                    else if ([ratingString isEqualToString:@"5"]) {
                        rating = [NSNumber numberWithInt:5];
                    }
                }
            }
        }
    
    // Do not submit the form if the rating is not selected
    if (self.descriptionTextView.text == nil || [self.descriptionTextView.text isEqualToString:@""]) {
        return;
    }
    
    // Progress HUD
	self.progressHUD = [NW_MBProgressHUD showHUDAddedTo:self.descriptionTextView animated:YES];
    self.progressHUD.labelText = @"Sending";
    self.progressHUD.removeFromSuperViewOnHide = YES;
    [self.progressHUD show:YES];
    
    // Save the email address to be prefilled in the next load
    if (self.emailTextField.text) {
        self.userEmailAddress = self.emailTextField.text;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:self.emailTextField.text forKey:@"NWFeedbackEmail"];
        [defaults synchronize];
    }
    
    if (!self.userEmailAddress)
        self.userEmailAddress = @"";
        
    // Post feedback response
    NWFeedback *feedback = [[NWFeedback alloc] initWithRating:rating];
    feedback.email = self.userEmailAddress;
    feedback.description = self.descriptionTextView.text;
    
    self.feedbackConnection = [[NWConnection alloc] initWithApplicationKey:[Neemware apiKey]];
    [self.feedbackConnection addObjectToSend:feedback];
    self.feedbackConnection.delegate = self;
    [self.feedbackConnection sendObjects];
    NWDLog(@"Done with sending feedback");
}

- (void)transferComplete:(NWConnection *)connection
{
    NWDLog(@"Transfer complete");
    [self cleanup];
    [self dismissFeedbackForm];
}

- (void)transferError:(NWConnection *)connection
{
    NWDLog(@"Transfer error");
    [self cleanup];
}

-(void)dismissFeedbackForm
{
    NWDLog(@"Dismissing Feedback form");
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissFeedbackForm:)])
        [self.delegate dismissFeedbackForm:self];
}

-(BOOL)isPad {
    return (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad);
}

@end
