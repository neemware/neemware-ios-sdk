//
//  NWInboxTableViewController.m
//  NeemwareSDK
//
//  Created by Erik Stromlund (neemware) on 8/7/12.
//  Copyright (c) 2012 Neemware, Inc. All rights reserved.
//

#import "NWInboxTableViewController.h"
#import "NWContentDataStore.h"
#import "NWContentData.h"
#import "Neemware.h"
#import "NWInboxCell.h"
#import "NWWebViewController.h"
#import "DTCustomColoredAccessory.h"
#import "SVPullToRefresh.h"

@implementation NWInboxTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        
        // Register the notification to trigger an inbox refresh when new data arrives
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inboxDataUpdated) name:@"kNWInboxDataChangedNotification" object:nil];
    }
    return self;
}

- (id) init
{
    self = [self initWithStyle:UITableViewStylePlain];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Set NavBar title
    self.title = @"Notifications";
    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:(25.0/255.0) green:(25.0/255.0) blue:(25.0/255.0) alpha:1.0]];
    
    // Add a close button to the navigationBar
    UIBarButtonItem *closeBBI = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(dismissInboxView)];
    self.navigationController.navigationBar.topItem.leftBarButtonItem = closeBBI;
    
    // Add a "Powered By Neemware" banner to bottom of screen
    // Make it a button so clicking it goes to Neemware website
    UIButton *pbnButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.navigationController.view.frame.size.height-20, self.navigationController.view.frame.size.width, 20)];
    [pbnButton setBackgroundColor:[UIColor colorWithRed:(25.0/255.0) green:(25.0/255.0) blue:(25.0/255.0) alpha:1.0]];
    [pbnButton setTitle:@"Powered By Neemware" forState:UIControlStateNormal];
    [pbnButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [pbnButton.titleLabel setFont:[UIFont systemFontOfSize:13]];
    [pbnButton.titleLabel setTextColor:[UIColor whiteColor]];
    [pbnButton addTarget:self action:@selector(displayNeemwareWebsite) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationController.view addSubview:pbnButton];

    // Set tableView separatorColor
//    [self.tableView setSeparatorColor:[UIColor colorWithRed:(0.0/255.0) green:(128.0/255.0) blue:(255.0/255.0) alpha:1.0]];
    
    // Set the rowHeight per design
    [self.tableView setRowHeight:58];
    
    // Add pull-to-refresh features
    [self.tableView addPullToRefreshWithActionHandler:^{
        [[NWContentDataStore sharedInstance] updateContentData];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Reload the data every time the tableView appears
    [[self tableView] reloadData];
//    [self updateInboxData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[[NWContentDataStore sharedInstance] allContent] count];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
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
        
//        cell.contentImageView.image = [UIImage imageNamed:@"question-icon24-v2.png"];
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
        
//        cell.contentImageView.image = [UIImage imageNamed:@"speaker_48.png"];
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
    if (rowContentData.contentImageURL)
    {
        //get a dispatch queue
        dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        //this will start the image loading in bg
        dispatch_async(concurrentQueue, ^{
            NSData *image = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:rowContentData.contentImageURL]];
            
            //this will set the image when loading is finished
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.contentImageView.image = [UIImage imageWithData:image];
            });
        });
    }
    
    // Otherwise, use these icons for message and question
    else
    {
        if ([rowContentData.contentType isEqualToString:@"message"])
            cell.contentImageView.image = [UIImage imageNamed:@"speaker_48.png"];
        else if ([rowContentData.contentType isEqualToString:@"question"])
            cell.contentImageView.image = [UIImage imageNamed:@"question-icon24-v2.png"];
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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Set the background color/image/view here
    NWContentData *cellContent = [[[NWContentDataStore sharedInstance] allContent] objectAtIndex:[indexPath row]];
    // Only set this stuff if it isn't an image cell
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
            DTCustomColoredAccessory *accessory = [DTCustomColoredAccessory accessoryWithColor:[UIColor colorWithRed:25.0/255.0 green:25.0/255.0 blue:25.0/255.0 alpha:1.0]];
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
    
    // And, pop it up on the screen, modally
    [self presentModalViewController:webController animated:YES];
}

// Called from "Powered By Neemware" button
-(void)displayNeemwareWebsite
{
//    NWWebViewController *webController = [[NWWebViewController alloc] initWithURL:@"http://www.neemware.com"];
//    [self presentModalViewController:webController animated:YES];
    NSURL *nwURL = [NSURL URLWithString:@"http://www.neemware.com"];
    [[UIApplication sharedApplication] openURL:nwURL];
}

#pragma mark - Inbox Methods

// This method is called by the "Close" barButtonItem in the inbox
- (void)dismissInboxView
{
    [self dismissModalViewControllerAnimated:YES];
}

// This method is called by the observer responding to @"kNWInboxDataChangedNotification"
- (void)inboxDataUpdated
{
    [[self tableView] reloadData];
    [self.tableView.pullToRefreshView stopAnimating];
    [self.tableView.pullToRefreshView setLastUpdatedDate:[NSDate date]];
}

- (void)updateInboxData
{
    [[self tableView].pullToRefreshView startAnimating];
    [[NWContentDataStore sharedInstance] updateContentData];
}

// Remove observers when this instance is removed from memory
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
