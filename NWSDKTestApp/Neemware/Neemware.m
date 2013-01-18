//
//  Neemware.m
//  NeemwareSDK
//
//  Created by Erik Stromlund on 8/7/12.
//  Copyright (c) 2013 Neemware, Inc. All rights reserved.
//

#import "Neemware.h"
#import "NWOpenUDID.h"
#import "NWContentDataStore.h"
#import "NWInboxTableViewController.h"
#import "NWFeedbackViewController.h"
#import "NWFeedbackConstants.h"
#import "NWBannerView.h"

static Neemware *sharedInstance = nil;
static NSString* kNWSDKVersion = @"1.0";
static NSString *kNWBaseURL = @"https://api.neemware.com/1/";

BOOL inboxIsLoaded;

@interface Neemware() <NWFeedbackFormDelegate>
{
    BOOL            _inboxIsLoaded;
    BOOL            _refreshDataOnLoad;
    NSTimer*        _updateTimer;
    NSString*       _apiKey;
    NSDictionary*   _locationData;
}

// Private properties
@property (nonatomic, copy)     NSString        *instanceAPIKey;
@property (nonatomic)           BOOL            instanceInboxIsLoaded;
@property (nonatomic, strong)   NSDictionary    *instanceLocationData;
@property (nonatomic)           NSInteger       instancePollingInterval;
@property (nonatomic)           BOOL            instanceRefreshDataOnLoad;
@property (nonatomic, strong)   UIColor         *instanceTitleBarColor;
@property (nonatomic, strong)   UIColor         *instanceTitleBarTextColor;
@property (nonatomic, copy)     NSString        *instanceUniqueID;
@property (nonatomic, strong)   NSTimer         *instanceUpdateTimer;
@property (nonatomic, strong)   NSDate          *sessionStartTime;

// Private methods
+ (id)sharedInstance;
- (id)initInstanceWithKey:(NSString *)apiKey pollingInterval:(NSInteger)interval;

@end

@implementation Neemware

@synthesize instanceAPIKey =                _apiKey;
@synthesize instanceLocationData =          _locationData;
@synthesize instanceUniqueID =              _uniqueID;
@synthesize instanceInboxIsLoaded =         _inboxIsLoaded;
@synthesize instanceRefreshDataOnLoad =     _refreshDataOnLoad;
@synthesize instanceUpdateTimer =           _updateTimer;
@synthesize instancePollingInterval =       _pollingInterval;
@synthesize sessionStartTime;

#pragma mark - Class setup methods
+ (Neemware *)sharedInstance {
    assert(sharedInstance != NULL);
    return sharedInstance;
}

/*
 * This init method must be called before using Neemware SDK using key/secret from Neemware website
 */
+ (void)loadWithApiKey:(NSString *)apiKey
{
    // Set default polling interval to 30
    sharedInstance = [[super alloc] initInstanceWithKey:apiKey pollingInterval:0];
}

+ (void)loadWithApiKey:(NSString *)apiKey pollInterval:(NSInteger)interval
{
    sharedInstance = [[super alloc] initInstanceWithKey:apiKey pollingInterval:interval];
}

- (id)initInstanceWithKey:(NSString *)apiKey pollingInterval:(NSInteger)interval
{
    self = [super init];
    if (self)
    {
        _apiKey = apiKey;
        _pollingInterval = interval;
        
        // We have not updated the inbox at this point so set it as no
        [self setInstanceInboxIsLoaded:NO];
        
        // If the polling interval is not zero, then setup the timer to poll at |_pollingInterval|
        if (_pollingInterval > 0)
        {
            [self startInstanceTimer];
            
            // Schedule the first update for 3 seconds from now
            [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(updateData) userInfo:nil repeats:NO];
        }
        
        // Register state change notifications for session management
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        
        [self setInstanceRefreshDataOnLoad:YES];
        
    }
    return self;
}

#pragma mark - Optional Setters

+ (void)setRefreshDataOnLoad:(BOOL)refresh
{
    [[self sharedInstance] setInstanceRefreshDataOnLoad:refresh];
}

+ (void)setUserLocationWithLatitude:(double)lat andLongitude:(double)lon
{
    NSString *latString = [NSString stringWithFormat:@"%f", lat];
    NSString *longString = [NSString stringWithFormat:@"%f", lon];
    NSDictionary *locationDict = [[NSDictionary alloc] initWithObjectsAndKeys:latString , @"lat", longString, @"lon", nil];
    [[self sharedInstance] setInstanceLocationData:locationDict];
}

+ (void)setTitleBarColor:(UIColor *)barColor
{
    [[self sharedInstance] setInstanceTitleBarColor:barColor];
}

+ (void)setTitleBarTextColor:(UIColor *)textColor
{
    [[self sharedInstance] setInstanceTitleBarTextColor:textColor];
}

#pragma mark - Accessors

+ (NSString *) inboxUnreadCount
{
    // Return nil instead of 0
    // This way it can be passed directly to badge methods (nil makes badge disappear, 0 appears as badge with "0")
    NSString *unreadCount = [[NWContentDataStore sharedInstance] unreadContentCount];
    if ([unreadCount isEqualToString:@"0"])
        return nil;
    else
        return [[NWContentDataStore sharedInstance] unreadContentCount];
}

+ (BOOL)refreshDataOnLoad
{
    return [[self sharedInstance] instanceRefreshDataOnLoad];
}

+ (NSString *) apiKey {
    return [[self sharedInstance] instanceAPIKey];
}

+ (NSDictionary *) location {
    return [[self sharedInstance] instanceLocationData];
}

+ (NSString *) latitude {
    return [[[self sharedInstance] instanceLocationData] objectForKey:@"lat"];
}

+ (NSString *) longitude {
    return [[[self sharedInstance] instanceLocationData] objectForKey:@"lon"];
}

+ (NSString *) udid {
    return [NWOpenUDID value];
}

+ (NSString *) version {
    return kNWSDKVersion;
}

+ (UIColor *)titleBarColor
{
    UIColor *tbc = [[self sharedInstance] instanceTitleBarColor];
    if (!tbc)
        tbc = [UIColor colorWithRed:(25.0/255.0) green:(25.0/255.0) blue:(25.0/255.0) alpha:1.0];
    return tbc;
}

+ (UIColor *)titleBarTextColor
{
    UIColor *tbtc = [[self sharedInstance] instanceTitleBarTextColor];
    if (!tbtc)
        tbtc = [UIColor whiteColor];
    return tbtc;
}

#pragma mark - Action Methods (refresh/update)
+ (void)refreshData
{
    [sharedInstance updateData];
}

#pragma mark - Action Methods (Banner)

// Present with default options; only |vController| is needed
+ (void)showBannerInViewController:(UIViewController *)vController
{
    [self showBannerInViewController:vController
                           withDelay:2
                modalTransitionStyle:UIModalTransitionStyleCoverVertical
              modalPresentationStyle:UIModalPresentationFullScreen
                           animation:YES];
}

+ (void)showBannerInViewController:(UIViewController *)vController
                         withDelay:(NSInteger)delay
              modalTransitionStyle:(UIModalTransitionStyle)ts
            modalPresentationStyle:(UIModalPresentationStyle)ps
                         animation:(BOOL)animated
{
    if ([NWBannerView bannerViewInViewController:vController]) {
        NWBannerView *bView = [NWBannerView bannerViewInViewController:vController];
        [NSTimer scheduledTimerWithTimeInterval:delay target:bView selector:@selector(showBanner) userInfo:nil repeats:NO];
    } else {
        NWBannerView *bannerView = [[NWBannerView alloc] initWithController:vController modalPresentationStyle:ps modalTransitionStyle:ts animation:animated];
        [vController.view addSubview:bannerView];
        bannerView = nil;
    }
}

#pragma mark - Action Methods (Inbox)

+ (void) displayInboxFrom:(UIViewController *)vc
{
    [self displayInboxFrom:vc
  withModalTransitionStyle:UIModalTransitionStyleCoverVertical
    modalPresentationStyle:UIModalPresentationFullScreen
                 animation:YES];
}

+ (void)displayInboxFrom:(UIViewController *)vc
withModalTransitionStyle:(UIModalTransitionStyle)ts
  modalPresentationStyle:(UIModalPresentationStyle)ps
               animation:(BOOL)animated
{
    if (!sharedInstance.instanceInboxIsLoaded)
        [sharedInstance updateData];
    
    NWInboxTableViewController *inboxTVC = [[NWInboxTableViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:inboxTVC];
    
    [navController setModalTransitionStyle:ts];
    [navController setModalPresentationStyle:ps];
    
    // presentViewController only works for iOS 5 and above
    if ([vc respondsToSelector:@selector(presentViewController:animated:completion:)])
        [vc presentViewController:navController animated:animated completion:nil];
    else
        [vc presentModalViewController:navController animated:animated];
}

#pragma mark - Session Management
- (void)startSession
{
    [self setSessionStartTime:[NSDate date]];
}

- (void)endSession
{
    __block UIBackgroundTaskIdentifier bgTask;
    bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    // Start the background task and return immediately.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self transmitSessionInfoToServer];
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    });
}

// Make sure to call this asynchronously because it uses a synchronous connection
- (void)transmitSessionInfoToServer
{
    // Modify the URL to include our parameters
    NSString *model = [UIDevice currentDevice].model;
    NSString *os    = [UIDevice currentDevice].systemName;
    NSString *osv   = [UIDevice currentDevice].systemVersion;
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    
    NSString *urlString = [kNWBaseURL stringByAppendingString:@"sessions"];
    urlString = [urlString stringByAppendingFormat:@"?api_key=%@&did=%@&v=%@&d_model=%@&d_os=%@&d_osv=%@&app_v=%@",
                 [Neemware apiKey], [Neemware udid], [Neemware version], model, os, osv, appVersion];
    
    if ([Neemware location])
        urlString =[urlString stringByAppendingFormat:@"&latitude=%@&longitude=%@", [Neemware latitude], [Neemware longitude]];
    
    // Calculate session length
    NSTimeInterval sessionLengthInSecs = [[NSDate date] timeIntervalSinceDate:self.sessionStartTime];
    self.sessionStartTime = nil;
    
    urlString = [urlString stringByAppendingFormat:@"&session_length=%d", (NSInteger)sessionLengthInSecs];
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    // Do a synchronous request because this method will be called asynchronously going into the background
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"POST"];
    
    [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
}

#pragma mark - Application Lifecycle Methods
- (void)applicationDidBecomeActive:(NSNotification *)not
{
    [self startInstanceTimer];
    [self startSession];
}

-(void)applicationWillResignActive:(NSNotification *)not
{
    [self invalidateUpdateTimer];
}

- (void)applicationWillTerminate:(NSNotification *)not
{
    [self endSession];
}

- (void)applicationDidEnterBackground:(NSNotification *)not
{
    [self endSession];
}

- (void)applicationWillEnterForeground:(NSNotification *)not
{
    if ([self instanceRefreshDataOnLoad])
        [self updateData];
}

#pragma mark - NSTimer/Update Methods
- (void)startInstanceTimer
{
    // Immediately return if the |pollingInterval| doesn't exist or is 0 (or negative, but it shouldn't be)
    if (!_pollingInterval || _pollingInterval < 1)
        return;
    
    if (!self.instanceUpdateTimer)
        [self setInstanceUpdateTimer:[NSTimer scheduledTimerWithTimeInterval:_pollingInterval target:self selector:@selector(updateData) userInfo:nil repeats:YES]];
}

- (void)updateData
{
    DLog(@"Neemware: Updating Data");
    [[NWContentDataStore sharedInstance] updateContentData];
    [self setInstanceInboxIsLoaded:YES];
}

- (void)invalidateUpdateTimer
{
    // Immediately return if the |instanceUpdateTimer| doesn't even exist
    if (!self.instanceUpdateTimer)
        return
        
        [[self instanceUpdateTimer] invalidate];
    self.instanceUpdateTimer = nil;
}

#pragma mark - Utility Methods

+ (BOOL)isPad {
    return (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad);
}

#pragma mark - Feedback related methods

+ (void)displayFeedbackFormIn:(UIViewController *)vc
{
    [self displayFeedbackFormIn:vc
       withModalTransitionStyle:UIModalTransitionStyleCoverVertical
         modalPresentationStyle:UIModalPresentationCurrentContext
                      animation:YES];
}

+ (void)displayFeedbackFormIn:(UIViewController *)vc
     withModalTransitionStyle:(UIModalTransitionStyle)ts
       modalPresentationStyle:(UIModalPresentationStyle)ps
                    animation:(BOOL)animated
{
    NWFeedbackViewController *fvc = [[NWFeedbackViewController alloc] initWithNibName:nil bundle:nil];
    fvc.delegate = (id)vc;
    
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:fvc];
    nc.navigationBar.barStyle = UIBarStyleBlackOpaque;
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:fvc
                                                                                  action:@selector(dismissFeedbackForm)];
    fvc.navigationItem.leftBarButtonItem = cancelButton;
    
    [nc setModalPresentationStyle:ps];
    [nc setModalTransitionStyle:ts];
    [vc presentModalViewController:nc animated:animated];
}
#pragma mark - Event tracking
+ (void)logEvent:(NSString *)eventName
{
    if (eventName && ![eventName isEqualToString:@""])
    {
        NSString *eventsEndpoint = @"events";
        
        // Modify the URL to include our parameters
        NSString *model = [UIDevice currentDevice].model;
        NSString *os    = [UIDevice currentDevice].systemName;
        NSString *osv   = [UIDevice currentDevice].systemVersion;
        NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
        
        NSString *urlString = [kNWBaseURL stringByAppendingString:eventsEndpoint];
        urlString = [urlString stringByAppendingFormat:@"?api_key=%@&did=%@&v=%@&d_model=%@&d_os=%@&d_osv=%@&app_v=%@",
                     [Neemware apiKey], [Neemware udid], [Neemware version], model, os, osv, appVersion];
        
        if ([Neemware location])
            urlString =[urlString stringByAppendingFormat:@"&latitude=%@&longitude=%@", [Neemware latitude], [Neemware longitude]];
        
        urlString = [urlString stringByAppendingFormat:@"&event_name=%@", eventName];
        urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSMutableURLRequest *ping = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
        [ping setHTTPMethod:@"POST"];
        
        DLog(@"event url ping: %@", urlString);
        // Async ping, we don't care to know results so don't set delegate or anything
        (void)[[NSURLConnection alloc] initWithRequest:ping delegate:nil];
    }
}

#pragma mark - Push stuff
+ (void)storeDeviceToken:(NSData *)theDeviceToken
{
    NSString *fixedDeviceToken = [[theDeviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    [fixedDeviceToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    if (fixedDeviceToken && ![fixedDeviceToken isEqualToString:@""])
    {
        NSString *endpoint = @"devices/register";
        
        // Modify the URL to include our parameters
        NSString *model = [UIDevice currentDevice].model;
        NSString *os    = [UIDevice currentDevice].systemName;
        NSString *osv   = [UIDevice currentDevice].systemVersion;
        NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
        
        NSString *urlString = [kNWBaseURL stringByAppendingString:endpoint];
        urlString = [urlString stringByAppendingFormat:@"?api_key=%@&did=%@&v=%@&d_model=%@&d_os=%@&d_osv=%@&app_v=%@",
                     [Neemware apiKey], [Neemware udid], [Neemware version], model, os, osv, appVersion];
        
        if ([Neemware location])
            urlString =[urlString stringByAppendingFormat:@"&latitude=%@&longitude=%@", [Neemware latitude], [Neemware longitude]];
        
        urlString = [urlString stringByAppendingFormat:@"&push_token=%@", fixedDeviceToken];
        urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSMutableURLRequest *ping = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
        [ping setHTTPMethod:@"POST"];
        
        DLog(@"register push token url ping: %@", urlString);
        // Async ping, we don't care to know results so don't set delegate or anything
        (void)[[NSURLConnection alloc] initWithRequest:ping delegate:nil];
    }
    
}

#pragma mark - FeedbackDelegate
- (void)dismissFeedbackForm:(NWFeedbackViewController *)feedbackForm
{
    if (feedbackForm)
        [feedbackForm dismissModalViewControllerAnimated:YES];
}


@end

