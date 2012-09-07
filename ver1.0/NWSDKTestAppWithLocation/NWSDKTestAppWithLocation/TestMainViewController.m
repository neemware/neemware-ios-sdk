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
@synthesize latitudeLabel;
@synthesize longitudeField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLocationLabels) name:@"kNWInboxDataChangedNotification" object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [self setLatitudeLabel:nil];
    [self setLongitudeField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)updateLocationLabels
{
    [[self latitudeLabel] setText:[Neemware latitude]];
    [[self longitudeField] setText:[Neemware longitude]];
}

- (IBAction)showInbox:(id)sender {
    [Neemware displayInboxFrom:self];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
