//
//  TestMainViewController.m
//  NeemwareSDK
//
//  Created by Erik Stromlund (neemware) on 8/7/12.
//  Copyright (c) 2012 Neemware, Inc. All rights reserved.
//

#import "TestMainViewController.h"
#import <Neemware/Neemware.h>

@interface TestMainViewController ()

@end

@implementation TestMainViewController
@synthesize unreadCount;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Neemware showBannerInViewController:self];
}

- (void)viewDidUnload
{
    [self setUnreadCount:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)showInbox:(id)sender {
    [Neemware displayInboxFrom:self];
}

- (IBAction)showFeedback:(id)sender {
    [Neemware displayFeedbackFormIn:self];
}
- (IBAction)updateCount:(id)sender {
    [[self unreadCount] setText:[Neemware inboxUnreadCount]];
}
@end
