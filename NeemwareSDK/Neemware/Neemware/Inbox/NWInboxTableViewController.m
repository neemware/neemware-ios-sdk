//
//  NWInboxTableViewController.m
//  NeemwareSDK
//
//  Created by Erik Stromlund (Neemware) on 8/7/12.
//  Copyright (c) 2013 Neemware, Inc. All rights reserved.
//

#import "NWInboxTableViewController.h"
#import "NWFeedbackViewController.h"
#import "NWContentDataStore.h"
#import "NWContentData.h"
#import "Neemware.h"
#import "NWInboxCell.h"
#import "NWWebViewController.h"
#import "NW_DTCustomColoredAccessory.h"
#import "NW_SVPullToRefresh.h"
#import <QuartzCore/QuartzCore.h>

@interface NWInboxTableViewController () <UIWebViewDelegate, UIPopoverControllerDelegate, NWFeedbackFormDelegate>

@property (nonatomic, strong) UIPopoverController *popController;
@property (strong) UIButton *pbnButton;
@property (strong) NSString *brandingText;

@end


@implementation NWInboxTableViewController
@synthesize pbnButton;
@synthesize brandingText;
@synthesize delegate;

#pragma mark - Class setup
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
    {
        // Register the notification to trigger an inbox refresh when new data arrives
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inboxDataUpdated) name:@"kNWInboxDataChangedNotification" object:nil];
    }
    return self;
}

- (id) init
{
    if (self = [self initWithStyle:UITableViewStylePlain])
    {
    }
    return self;
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];

    // Set NavBar title
    self.title = [[NWContentDataStore sharedInstance] messageCenterTitleText];
    
    [self.navigationController.navigationBar setTintColor:[Neemware titleBarColor]];
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[Neemware titleBarTextColor], UITextAttributeTextColor, nil]];
    
    // Add a close button to the navigationBar
    UIBarButtonItem *closeBBI = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(dismissInboxView)];
    [closeBBI setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[Neemware titleBarTextColor], UITextAttributeTextColor, nil] forState:UIControlStateNormal];
    self.navigationController.navigationBar.topItem.leftBarButtonItem = closeBBI;
    
    // Add a feedback button to the navigationBar
    UIBarButtonItem *feedbackBBI = [[UIBarButtonItem alloc] initWithTitle:[[NWContentDataStore sharedInstance] feedbackButtonText] style:UIBarButtonItemStylePlain target:self action:@selector(showFeedbackForm)];
    [feedbackBBI setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[Neemware titleBarTextColor], UITextAttributeTextColor, nil] forState:UIControlStateNormal];
    self.navigationController.navigationBar.topItem.rightBarButtonItem = feedbackBBI;
    
    // Magic number from look and feel/trial-and-error
    [self.tableView setRowHeight:68];
    
    // Add pull-to-refresh
    [self.tableView addPullToRefreshWithActionHandler:^{
        [[NWContentDataStore sharedInstance] updateContentData];
    }];
    
    // Create the branding banner, but don't display it yet
    if (!self.pbnButton)
    {
        self.pbnButton = [[UIButton alloc] initWithFrame:CGRectMake(0,
                                                                    self.navigationController.view.frame.size.height-20,
                                                                    self.navigationController.view.frame.size.width,
                                                                    20)];
        [self.pbnButton setBackgroundColor:[UIColor colorWithRed:(25.0/255.0) green:(25.0/255.0) blue:(25.0/255.0) alpha:1.0]];
        [self.pbnButton.titleLabel setTextAlignment:UITextAlignmentCenter];
        [self.pbnButton.titleLabel setFont:[UIFont systemFontOfSize:13]];
        [self.pbnButton.titleLabel setTextColor:[UIColor whiteColor]];
        [self.pbnButton addTarget:self action:@selector(displayNeemwareWebsite) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[self tableView] reloadData];
    
    brandingText = [[NWContentDataStore sharedInstance] brandingText];
    if (brandingText && ![brandingText isEqualToString:@""])
    {
        [self.pbnButton setTitle:brandingText forState:UIControlStateNormal];
        [self.navigationController.view addSubview:pbnButton];
    } else
    {
        [self.pbnButton removeFromSuperview];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    if ([self.popController isPopoverVisible])
    {
        [self.popController dismissPopoverAnimated:NO];
        self.popController = nil;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Device Rotation Methods
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (self.pbnButton)
        self.pbnButton.frame = CGRectMake(0,
                                          self.navigationController.view.frame.size.height-20,
                                          self.navigationController.view.frame.size.width,
                                          20);
}

#pragma mark - Action methods
- (void)showFeedbackForm
{
    NWFeedbackViewController *fvc = [[NWFeedbackViewController alloc] initWithNibName:nil bundle:nil];
    fvc.delegate = self;
    
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:fvc];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:fvc action:@selector(dismissFeedbackForm)];
    [cancelButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[Neemware titleBarTextColor], UITextAttributeTextColor, nil] forState:UIControlStateNormal];
    fvc.navigationItem.leftBarButtonItem = cancelButton;
    
    if ([self isPad])
    {
        if (self.popController && [self.popController isPopoverVisible])
            [self.popController dismissPopoverAnimated:YES];
        else
        {
            if (!self.popController)
                self.popController = [[UIPopoverController alloc] initWithContentViewController:nc];
            [self.popController setPopoverContentSize:CGSizeMake(320, 480)];
            [self.popController setDelegate:self];
            [self.popController presentPopoverFromBarButtonItem:self.navigationController.navigationBar.topItem.rightBarButtonItem
                                      permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }
    else
    {
        // presentViewController only works for iOS5 and above
        if ([self respondsToSelector:@selector(presentViewController:animated:completion:)])
            [self presentViewController:nc animated:YES completion:nil];
        else
            [self presentModalViewController:nc animated:YES];
    }
}

// Called from branding/"Powered By Neemware" button
- (void)displayNeemwareWebsite
{
    NSURL *nwURL = [NSURL URLWithString:@"http://www.neemware.com"];
    [[UIApplication sharedApplication] openURL:nwURL];
}

// This method is called by the "Close" barButtonItem in the inbox
- (void)dismissInboxView
{
    if (self.delegate)
        [self.delegate dismissInbox];
    else
    {
        // dismissViewControllerAnimated:... only works on iOS 5 and above
        if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)])
            [self dismissViewControllerAnimated:YES completion:nil];
        else
            [self dismissModalViewControllerAnimated:YES];
    }
}

#pragma mark - Utility Methods

- (BOOL)isPad {
    return (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad);
}

#pragma mark - UITableView Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[NWContentDataStore sharedInstance] allContent] count];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    // Add an empty footer to tableView to stop empty rows from filling the blank space
    return [UIView new];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Get the data for the content corresponding to this row
    NWContentData *rowContentData = [[[NWContentDataStore sharedInstance] allContent] objectAtIndex:[indexPath row]];
    
    // We're using a sub-classed UITableViewCell so we can add an imageView on the left and resize the text labels accordingly
    NWInboxCell *cell = nil;
    
    //  Set up the cells - some content has a title, some does not - so we need to use different cells
    NSInteger textFontSize = 16;
    NSInteger detailTextFontSize = 13;
    
    if (rowContentData.cellBackgroundImageURL)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NWImageBannerCell"];
        if (!cell)
        {
            cell = [[NWInboxCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NWImageBannerCell"];
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.contentImageView = nil;
        }
        
        cell.textLabel.text = @"";
        cell.detailTextLabel.text = @"";
    }
    else if (rowContentData.contentBody == nil || [rowContentData.contentBody isEqualToString:@""])
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NWCellNoTitle"];
        if (!cell)
            cell = [[NWInboxCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NWCellNoTitle"];
        
        // Configure the text (textLabel)
        cell.textLabel.numberOfLines = 2;
        cell.textLabel.text = rowContentData.contentSubject;
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NWCellWithTitle"];
        if (!cell)
            cell = [[NWInboxCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"NWCellWithTitle"];
        
        // Configure the title (textLabel)
        cell.textLabel.numberOfLines = 1;
        cell.textLabel.text = rowContentData.contentSubject;
        
        // Configure the subtitle (detailTextLabel)
        cell.detailTextLabel.numberOfLines = 1;
        cell.detailTextLabel.text = rowContentData.contentBody;
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
    }
    
    
    // Distinguish between un-read and read content by bolding or not-bolding
    if (rowContentData.contentRead)
    {
        cell.textLabel.font = [UIFont systemFontOfSize:textFontSize];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:detailTextFontSize];
    }
    else
    {
        cell.textLabel.font = [UIFont boldSystemFontOfSize:textFontSize];
        cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:detailTextFontSize];
    }
    
    // Configure the accessory type to be a disclosure indicator
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    // If there is an imageURL returned, then asynchronously download and display it
    if (rowContentData.contentIconURL)
    {
        //get a dispatch queue
        dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        //this will start the image loading in bg
        dispatch_async(concurrentQueue, ^{
            NSString *url = rowContentData.contentIconURL;
            if (![url hasPrefix:@"http://"])
                url = [NSString stringWithFormat:@"http://%@", rowContentData.contentIconURL];
            NSData *image = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:10] returningResponse:nil error:nil];

            //this will set the image when loading is finished
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.contentImageView.image = [UIImage imageWithData:image];
            });
        });
    }
    
    // Set the background image if there is one
    if (rowContentData.cellBackgroundImageURL)
    {
        //get a dispatch queue
        dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        //this will start the image loading in bg
        dispatch_async(concurrentQueue, ^{
            NSData *image = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:rowContentData.cellBackgroundImageURL]];
            
            //this will set the image when loading is finished
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:image]];
            });
        });
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.contentImageView.image = nil;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    return cell;
}

#pragma mark - UITableView delegate
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NWContentData *cellContent = [[[NWContentDataStore sharedInstance] allContent] objectAtIndex:[indexPath row]];

    // Only set this stuff if it isn't an image-only cell
    if (!cellContent.cellBackgroundImageURL)
    {
        if (cellContent.contentRead)
        {
            cell.backgroundColor = [UIColor whiteColor];
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        else {
            cell.backgroundColor = [UIColor colorWithRed:(240.0/255.0) green:(240.0/255.0) blue:(240.0/255.0) alpha:1.0];
            
            // Make a blue disclosure indicator programatically using custom class
            NW_DTCustomColoredAccessory *accessory = [NW_DTCustomColoredAccessory accessoryWithColor:[UIColor colorWithRed:25.0/255.0 green:25.0/255.0 blue:25.0/255.0 alpha:1.0]];
            accessory.highlightedColor = [UIColor blackColor];
            cell.accessoryView = accessory;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Deselect the row so it doesn't stay highlighted
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Get the data for the content corresponding to this row
    NWContentData *rowContentData = [[[NWContentDataStore sharedInstance] allContent] objectAtIndex:[indexPath row]];

    // Mark this content as read
    [[NWContentDataStore sharedInstance] userReadContent:rowContentData];
    
    // Initialize a webviewcontroller with the content
    NWWebViewController *webController = [[NWWebViewController alloc] initWithContent:rowContentData];
    
    [webController setModalTransitionStyle:[self.navigationController modalTransitionStyle]];
    [webController setModalPresentationStyle:[self.navigationController modalPresentationStyle]];
    
    // presentViewController only works on iOS 5 and above
    if ([self respondsToSelector:@selector(presentViewController:animated:completion:)])
        [self presentViewController:webController animated:YES completion:nil];
    else
        [self presentModalViewController:webController animated:YES];
}

#pragma mark - Inbox Methods

- (void)updateInboxData
{
    [[self tableView].pullToRefreshView startAnimating];
    [[NWContentDataStore sharedInstance] updateContentData];
}

// This method is called by the observer responding to @"kNWInboxDataChangedNotification"
- (void)inboxDataUpdated
{
    [[self tableView] reloadData];
    [self.tableView.pullToRefreshView stopAnimating];
    [self.tableView.pullToRefreshView setLastUpdatedDate:[NSDate date]];
}

#pragma mark - UIPopoverController delegate methods
- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    return YES;
}

#pragma mark - NWFeedbackForm Delegate methods
-(void)dismissFeedbackForm:(NWFeedbackViewController *)feedbackForm
{
    NWDLog(@"In Delegate: Dismissing form");
    if ([self isPad] && self.popController && [self.popController isPopoverVisible])
        [self.popController dismissPopoverAnimated:YES];
    else
    {
        // dismissViewController only works for iOS 5 and above
        if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)])
            [self dismissViewControllerAnimated:YES completion:nil];
        else
            [self dismissModalViewControllerAnimated:YES];
    }
}

@end
