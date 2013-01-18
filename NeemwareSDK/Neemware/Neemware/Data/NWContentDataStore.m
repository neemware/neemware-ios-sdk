//
//  NWContentDataStore.m
//  NeemwareSDK
//
//  Created by Erik Stromlund (Neemware) on 8/7/12.
//  Copyright (c) 2013 Neemware, Inc. All rights reserved.
//

#import "NWContentDataStore.h"
#import "NWContentData.h"
#import "NW_JSONKit.h"
#import "Neemware.h"

static NSString* kNWBaseAPIURL = @"https://api.neemware.com/1";
static NSString* kNWInboxDataChangedNotification = @"kNWInboxDataChangedNotification";
static NSString* kNWContentWasReadNotification = @"kNWContentWasReadNotification";
static NWContentDataStore *sharedInstance = nil;

static NSString* kNWLoadInboxEndPoint = @"/contents";

@implementation NWContentDataStore

@synthesize responseData           = _responseData;
@synthesize unreadContentCount     = _unreadContentCount;
@synthesize timestamp              = _timestamp;
@synthesize brandingText           = _brandingText;
@synthesize feedbackButtonText     = _feedbackButtonText;
@synthesize messageCenterTitleText = _messageCenterTitleText;

#pragma mark - Class setup
+ (NWContentDataStore *) sharedInstance
{
    if (!sharedInstance)
    {
        sharedInstance = [[super alloc] init];
    }
    return sharedInstance;
}

- (id)init
{
    if (self = [super init])
    {
        if (!_allContent)
            _allContent = [[NSMutableArray alloc] init];
        
        _messageCenterTitleText = @"Messages";
        _feedbackButtonText     = @"Feedback";
    }
    return self;
}

#pragma mark - Accessors

// Banners will call this method to get the next content to display
// This should return the first eligible object that it finds
// Specifically, the object should not have been 'read' yet,
// and it must be marked for display in the banner
- (NWContentData *)nextObjectToDisplayInBanner
{
    // Stop if we don't even have anything to search
    if (!_allContent)
        return nil;
    
    // Loop through allContent and return first object that is unread and marked for banner display
    for (NWContentData *cont in self.allContent)
    {
        if (!cont.contentRead && cont.showInBanner)
        {
            return cont;
        }
    }
    return nil;
}

- (NSString *)unreadContentCount
{
    NSInteger urCount = 0;
    for (NWContentData *content in _allContent)
        if (!content.contentRead)
            urCount = urCount + 1;
    return [NSString stringWithFormat:@"%d", urCount];
}

- (NSArray *) allContent
{
    // Return an immutable array of all content objects (_allContent is otherwise mutable)
    return [NSArray arrayWithArray:_allContent];
}

#pragma mark - Generate Request to Server

// Generate inboxURL based on endpoints, parameters, etc.
- (NSURL *)inboxURL
{
    NSString *model = [UIDevice currentDevice].model;
    NSString *os    = [UIDevice currentDevice].systemName;
    NSString *osv   = [UIDevice currentDevice].systemVersion;
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    
    NSString *urlString = [kNWBaseAPIURL stringByAppendingString:kNWLoadInboxEndPoint];
    urlString = [urlString stringByAppendingFormat:@"?api_key=%@&did=%@&v=%@&d_model=%@&d_os=%@&d_osv=%@&app_v=%@", [Neemware apiKey], [Neemware udid], [Neemware version], model, os, osv, appVersion];
    
    if ([Neemware location])
        urlString =[urlString stringByAppendingFormat:@"&latitude=%@&longitude=%@", [Neemware latitude], [Neemware longitude]];
    
    return [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

- (void)updateContentData
{
    [self setResponseData:[[NSMutableData alloc] init]];
    NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:[self inboxURL] cachePolicy:NSURLRequestReloadRevalidatingCacheData timeoutInterval:10];
    (void)[[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];  // (void) silences unused result errors
}

#pragma mark - Server Response Parsing and Object Generation

- (void)parseInboxData:(NSData *)data
{
    NSDictionary *responseDict;
    if ([data respondsToSelector:@selector(objectFromJSONData)])
        responseDict = [data objectFromJSONData];
    else
    {
        NWDLog(@"*** Neemware Error: Unable to parse data.  Did you include the -ObjC flag in 'Other Linker Flags' under Build Settings?  If you did and this error is still occuring, please contact Neemware support.");

        // Call it anyway so we get the error/trace
        responseDict = [data objectFromJSONData];
    }
    
    ////////////////////////////////////////////////////////
    // This stuff is sent back by server no matter what
    // Set the returned branding text (i.e. 'Powered by Neemware')
    [self setBrandingText:[responseDict objectForKey:@"branding"]];
    
    [self setMessageCenterTitleText:[responseDict objectForKey:@"message_center_title"]];
    if (!_messageCenterTitleText || [_messageCenterTitleText isEqualToString:@""])
        [self setMessageCenterTitleText:@"Messages"];
    
    [self setFeedbackButtonText:[responseDict objectForKey:@"feedback_button_text"]];
    if (!_feedbackButtonText || [_feedbackButtonText isEqualToString:@""])
        [self setFeedbackButtonText:@"Feedback"];
    
    // Get the unread_count and populate the variable
    [self setUnreadContentCount:[[responseDict objectForKey:@"unread_count"] stringValue]];
    ////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////
    // Check and see if there is any content to update before proceeding
    
    // Check if server returns update_client == true; stop if NO, continue if YES
    if ([[responseDict objectForKey:@"update_client"] boolValue] == YES)
    {
        // Update the local timestamp to the server's when the content is updated
        NSInteger updateTime = [[responseDict objectForKey:@"timestamp"] integerValue];
        if (updateTime)
            [self setTimestamp:updateTime];
        
        // Pull content and create objects
        NSDictionary *contentsDict = [responseDict objectForKey:@"contents"];

        BOOL itemForBanner = NO;
        NSMutableArray *objArray = [[NSMutableArray alloc] init];
        for (NSDictionary *objDict in contentsDict)
        {
            NWContentData *dataObj = [[NWContentData alloc] initWithDictionary:objDict];
            
            // Send to display in banner if it isn't yet read, and it is marked to showInBanner
            if (!dataObj.contentRead && dataObj.showInBanner)
                itemForBanner = YES;
            
            [objArray addObject:dataObj];
        }
        
        // Set the allContent array to the tempArray
        [self populateAllContentWithItems:objArray];
        
        // Notify banners if there is content to display
        if (itemForBanner)
            [self notifyBannersOfNewContent];
    }
    ////////////////////////////////////////////////////////
    
    // Send out notification that content has updated (or not - but it is at least done updating)
    [[NSNotificationCenter defaultCenter] postNotificationName:kNWInboxDataChangedNotification object:nil];
}

- (void) populateAllContentWithItems:(NSArray *)arr
{
    _allContent = [NSMutableArray arrayWithArray:arr];
}

#pragma mark - (Local) Notification Methods
- (void)notifyBannersOfNewContent
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kNWNewBannerContentAvailable" object:nil userInfo:nil];
}

- (void)userAnsweredQuestion:(NWContentData *)question
{
    [_allContent removeObject:question];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNWInboxDataChangedNotification object:nil userInfo:nil];
}

- (void)userReadContent:(NWContentData *)content
{
    // Update locally
    [content markAsRead];
    
    // Notify server with async call
    [self notifyServerThatUserReadContent:content];
    
    // Send out notification so banners can disappear if they were going to show this content
    // Make a dictionary with enough information to uniquely ID the content
    NSDictionary *contDict = [NSDictionary dictionaryWithObjectsAndKeys:content.contentType, @"content_type",
                              content.contentID, @"content_id", nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNWContentWasReadNotification object:nil userInfo:contDict];
}

#pragma mark - (Server) Notification Methods
- (void)notifyServerThatUserReadContent:(NWContentData *)cont
{
    // Get the controller portion of the route by adding an 's' to the contentType
    NSString *contentControllerName = [NSString stringWithFormat:@"%@s", cont.contentType];
    
    // Get the entire route by appending that, ID, plus 'read' action, to baseURL
    NSString *urlString = [kNWBaseAPIURL stringByAppendingFormat:@"/%@/%@/read", contentControllerName, cont.contentID];
    
    // Append the parameters
    NSString *model = [UIDevice currentDevice].model;
    NSString *os    = [UIDevice currentDevice].systemName;
    NSString *osv   = [UIDevice currentDevice].systemVersion;
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];

    urlString = [urlString stringByAppendingFormat:@"?id=%@&api_key=%@&did=%@&v=%@&d_model=%@&d_os=%@&d_osv=%@&app_v=%@", [cont contentID], [Neemware apiKey], [Neemware udid], [Neemware version], model, os, osv, appVersion];

    if ([Neemware location])
        urlString =[urlString stringByAppendingFormat:@"&latitude=%@&longitude=%@", [Neemware latitude], [Neemware longitude]];
    
    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableURLRequest *ping = [[NSMutableURLRequest alloc] initWithURL:url];
    [ping setHTTPMethod:@"PUT"];
    
    // Async ping, we don't care to know results so don't set delegate or anything
    (void)[[NSURLConnection alloc] initWithRequest:ping delegate:nil]; // (void) silences unused result errors
}

#pragma mark - NSURLConnection Delegate Methods
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    //    NSLog(@"Did receive response");
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NWDLog(@"Neemware: Error loading inbox data: %@", error.localizedDescription);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // Once this method is invoked, "responseData" contains the complete result
    [self parseInboxData:self.responseData];
}

@end
