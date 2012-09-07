//
//  NWContentDataStore.m
//  NeemwareSDK
//
//  Created by Erik Stromlund (neemware) on 8/7/12.
//  Copyright (c) 2012 Neemware, Inc. All rights reserved.
//

#import "NWContentDataStore.h"
#import "NWContentData.h"
#import "Neemware.h"

static NSString* kNWInboxDataChangedNotification = @"kNWInboxDataChangedNotification";
static NSString* kNWContentWasReadNotification = @"kNWContentWasReadNotification";
static NWContentDataStore *sharedInstance = nil;

static NSString* kNWBaseURL = @"http://staging-api.neemware.com/1/";
//static NSString* kNWBaseURL = @"http://www.neemware.com/demo/test/";
//static NSString* kNWBaseURL = @"file:///Users/erikneemware/";

static NSString* kNWLoadInboxEndPoint = @"contents/fetch.json";
//static NSString* kNWLoadInboxEndPoint = @"inboxtest.json";
//static NSString* kNWLoadInboxEndPoint = @"test.json";

@implementation NWContentDataStore

@synthesize responseData = _responseData;
@synthesize unreadContentCount = _unreadContentCount;

+(NWContentDataStore *) sharedInstance
{
    if (!sharedInstance)
    {
        sharedInstance = [[super alloc] init];
    }
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        if (!_allContent)
            _allContent = [[NSMutableArray alloc] init];
    }
    return self;
}

// Generate inboxURL based on endpoints, parameters, etc.
- (NSURL *)inboxURL
{
    NSLog(@"inboxURL");
    // Modify the URL to include our parameters
    NSString *model = [UIDevice currentDevice].model;
    NSString *os    = [UIDevice currentDevice].systemName;
    NSString *osv   = [UIDevice currentDevice].systemVersion;
    
    NSString *urlString = [kNWBaseURL stringByAppendingString:kNWLoadInboxEndPoint];
    urlString = [[urlString stringByAppendingFormat:@"?api_key=%@&did=%@&v=%@&d_model=%@&d_os=%@&d_osv=%@", [Neemware apiKey], [Neemware udid], [Neemware version], model, os, osv] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if ([Neemware location])
        urlString =[urlString stringByAppendingFormat:@"&lat=%@&lng=%@", [Neemware latitude], [Neemware longitude]];
    
    NSLog(@"Current inboxURL: %@", urlString);
    return [NSURL URLWithString:urlString];
}

- (void)updateContentData
{
    NSLog(@"updateContentData");
    [self setResponseData:[[NSMutableData alloc] init]];
    NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:[self inboxURL]];
    [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
}

- (void)parseInboxData:(NSData *)data
{
    NSError *error = nil;
    NSDictionary *responseDict = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

//    NSLog(@"Response Dict: %@", responseDict);
    // Get the unread_count and populate the variable
    [self setUnreadContentCount:[[responseDict objectForKey:@"unread_count"] stringValue]];
    
    // Pull content portion and create objects
    NSDictionary *contentsDict = [responseDict objectForKey:@"contents"];
    if (error)
        NSLog(@"dataDict Parsing Error: %@", error.localizedDescription);
    else
    {
        BOOL itemForBanner = NO;
        NSMutableArray *objArray = [[NSMutableArray alloc] init];
        for (NSDictionary *objDict in contentsDict)
        {
            NWContentData *dataObj = [[NWContentData alloc] initWithDictionary:objDict];
            // Send to display in banner if it isn't yet read, and it is marked to showInBanner
            if (!dataObj.contentRead && dataObj.showInBanner)
            {
                NSLog(@"Found item to display in banner");
                itemForBanner = YES;
            }
            
            // Add individual object to tempArray
            [objArray addObject:dataObj];
        }
        
        // Set the allContent array to the tempArray
        [self populateWithItems:objArray];
        
        // Notify banners if there is content to display
        if (itemForBanner)
            [self notifyBannersOfNewContent];
    }
    
    // Send out notification that content has updated
    [[NSNotificationCenter defaultCenter] postNotificationName:kNWInboxDataChangedNotification object:nil];
}

- (void)notifyBannersOfNewContent
{
    NSLog(@"Notifying banners of new content");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kNWNewBannerContentAvailable" object:nil userInfo:nil];
}

- (void) populateWithItems:(NSArray *)arr
{
    _allContent = [NSMutableArray arrayWithArray:arr];
}

- (NSArray *) allContent
{
    // Return an immutable array of all content objects
    return [NSArray arrayWithArray:_allContent];
}

- (void) userReadContent:(NWContentData *)content
{
    // Update local model
    [content markAsRead];
    
    // Notify server with async call
    [self notifyServerThatUserReadContent:content];
    
    // Send out notification so banners can disappear if they were going to show this content
    // Make a dictionary with enough information to uniquely ID the content
    NSDictionary *contDict = [NSDictionary dictionaryWithObjectsAndKeys:content.contentType, @"content_type",
                                                                        content.contentID, @"content_id", nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNWContentWasReadNotification object:nil userInfo:contDict];
}

- (void)userAnsweredQuestion:(NWContentData *)question
{
//    NSLog(@"User answered question");
    // Remove cell from table -- server itself tracks if question is answered or not
//    NSLog(@"allContent count: %d", [_allContent count]);
    [_allContent removeObject:question];
//    NSLog(@"allContent count after: %d", [_allContent count]);
    [[NSNotificationCenter defaultCenter] postNotificationName:kNWInboxDataChangedNotification object:nil userInfo:nil];
}

- (void)notifyServerThatUserReadContent:(NWContentData *)cont
{
    // Get the controller portion of the route by adding an 's' to the contentType
    NSString *contentControllerName = [NSString stringWithFormat:@"%@s", cont.contentType];
    
    // Get the entire route by appending that, plus 'read' action, to baseURL
    NSString *urlString = [kNWBaseURL stringByAppendingFormat:@"%@/read", contentControllerName];
    
    // Append the parameters
    urlString = [urlString stringByAppendingFormat:@"?id=%@&api_key=%@&did=%@&v=%@", [cont contentID], [Neemware apiKey], [Neemware udid], [Neemware version]];

    // Append the location parameters, if any
    if ([Neemware location])
        urlString =[urlString stringByAppendingFormat:@"&lat=%@&lng=%@", [Neemware latitude], [Neemware longitude]];
    
    NSURLRequest *ping = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    
    // Async ping, we don't care to know results so don't set delegate or anything
    [[NSURLConnection alloc] initWithRequest:ping delegate:nil];
}

-(NSString *)unreadContentCount
{
    NSInteger urCount = 0;
    for (NWContentData *content in _allContent)
        if (!content.contentRead)
            urCount = urCount + 1;
    return [NSString stringWithFormat:@"%d", urCount];
}

#pragma mark NSURLConnection Delegate Methods
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
    NSLog(@"Error loading inbox data: %@", error.localizedDescription);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // Once this method is invoked, "responseData" contains the complete result
    [self parseInboxData:self.responseData];
}

#pragma mark - Banner methods
// Banners will call this method to get the next content to display
// This should return the first eligible object that it finds
// Specifically, the object should not have been 'read' yet,
// and it must be marked for display in the banner
-(NWContentData *)nextObjectToDisplayInBanner
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

@end
