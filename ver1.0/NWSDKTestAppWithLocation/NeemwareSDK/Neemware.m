//
//  Neemware.m
//  NeemwareSDK
//
//  Created by Erik Stromlund on 8/7/12.
//  Copyright (c) 2012 Neemware, Inc. All rights reserved.
//

#import "Neemware.h"
#import "NWOpenUDID.h"
#import "NWContentDataStore.h"
#import "NWInboxTableViewController.h"
#import "NWBannerView.h"

static Neemware *sharedInstance = nil;

static NSString* kNWSDKVersion = @"2.0";

BOOL inboxIsLoaded;

@interface Neemware()
{
    BOOL            _inboxIsLoaded;
    NSTimer*        _updateTimer;
}
// Private properties
@property (nonatomic, copy)     NSString        *instanceAPIKey;
//@property (nonatomic, copy)     NSString        *instanceUserID;
@property (nonatomic, copy)     NSString        *instanceUniqueID;
@property (nonatomic, strong)   NSDictionary    *instanceLocationData;
@property (nonatomic, strong)   NSDictionary    *instanceCustomUserInformation;
@property (nonatomic, strong)   NSTimer         *instanceUpdateTimer;
@property (nonatomic)           BOOL            instanceInboxIsLoaded;
@property (nonatomic)           NSInteger       instanceUpdateInterval;

// Private methods
+ (id)sharedInstance;
- (id)initInstanceWithKey:(NSString *)apiKey;

@end

@implementation Neemware

#pragma mark - Instance Accessors
@synthesize instanceAPIKey =                _apiKey;
//@synthesize instanceUserID =                _userID;
@synthesize instanceLocationData =          _locationData;
@synthesize instanceUniqueID =              _uniqueID;
@synthesize instanceCustomUserInformation = _customUserInformation;
@synthesize instanceInboxIsLoaded =         _inboxIsLoaded;
@synthesize instanceUpdateInterval =        _updateInterval;
@synthesize instanceUpdateTimer =           _updateTimer;

// This sharedInstance will represent every instance of this class that is created
+ (Neemware *)sharedInstance {
    // Check whether the instance is initialized
    assert(sharedInstance != NULL);
    return sharedInstance;
}

/**
 * This init method must be called before using Neemware SDK using key/secret from Neemware website
 */
+ (void)loadWithApiKey:(NSString *)apiKey
{
    sharedInstance = [[super alloc] initInstanceWithKey:apiKey];
}

// Create the instance
- (id) initInstanceWithKey:(NSString *)apiKey
{
    self = [super init];
    if (self)
    {
        _apiKey = apiKey;
        
        // We have not updated the inbox at this point so set it as no
        [self setInstanceInboxIsLoaded:NO];
        
        // If user doesn't set update interval, then use the default
        NSInteger defaultUpdateInterval = 30; //seconds
        if (![self instanceUpdateInterval])
            [self setInstanceUpdateInterval:defaultUpdateInterval];
        
        // Schedule the repeating update timer
        [self startInstanceTimer];
        
        // Schedule the first update for 3 seconds from now
        [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(updateData) userInfo:nil repeats:NO];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
     }
    return self;
}

-(void)applicationDidBecomeActive:(NSNotification *)not
{
    NSLog(@"applicationDidBecomeActive");
    [self startInstanceTimer];
}

-(void)applicationWillResignActive:(NSNotification *)not
{
    NSLog(@"applicationWillResignActive");
    [self invalidateUpdateTimer];
}

-(void)startInstanceTimer
{
    if (!self.instanceUpdateTimer)
    {
        [self setInstanceUpdateTimer:[NSTimer scheduledTimerWithTimeInterval:[self instanceUpdateInterval] target:self selector:@selector(updateData) userInfo:nil repeats:YES]];
    }
    else
        NSLog(@"There was already a timer");
}

-(void)invalidateUpdateTimer
{
    [[self instanceUpdateTimer] invalidate];
    self.instanceUpdateTimer = nil;
}

#pragma mark - Optional Class User Data Setters
/**
 * Use these to set your own (optional) custom properties
 **/
+ (void)setUpdateInterval:(NSInteger)updateInterval
{
    // Set the new interval
    [[self sharedInstance] setInstanceUpdateInterval:updateInterval];
    
    // Stop the old timer
    [[[self sharedInstance] instanceUpdateTimer] invalidate];

    // Replace it with (and start) the new timer
    [[self sharedInstance] setInstanceUpdateTimer:[NSTimer scheduledTimerWithTimeInterval:updateInterval target:sharedInstance selector:@selector(updateData) userInfo:nil repeats:YES]];
}

//+ (void)setUserID:(NSString *)uid
//{
//    [[self sharedInstance] setInstanceUserID:uid];
//}

+ (void)setUserLocationWithLatitude:(double)lat andLongitude:(double)lon
{
    // CLLocation.coordinates.longitude & ...latitude come as 'aka double' type
    // We're going to save these doubles as strings so they are ready to send to server when needed
    NSString *latString = [NSString stringWithFormat:@"%f", lat];
    NSString *longString = [NSString stringWithFormat:@"%f", lon];
    NSDictionary *locationDict = [[NSDictionary alloc] initWithObjectsAndKeys:latString , @"lat", longString, @"lon", nil];
    [[self sharedInstance] setInstanceLocationData:locationDict];
    
    // And test it
    NSLog(@"Just set location to:\nLat: %@,\nLong: %@", [Neemware latitude], [Neemware longitude]);
}

+ (void)setCustomUserInformation:(NSDictionary *)dict
{
    [[self sharedInstance] setInstanceCustomUserInformation:dict];
}

#pragma mark - Class User Data Accessors
/**
 * Accessors
 */
+ (NSString *) apiKey
{
    return [[self sharedInstance] instanceAPIKey];
}

//+ (NSString *) userID
//{
//    return [[self sharedInstance] instanceUserID];
//}

+ (NSDictionary *) location
{
    return [[self sharedInstance] instanceLocationData];
}

+ (NSString *) latitude
{
    return [[[self sharedInstance] instanceLocationData] objectForKey:@"lat"];
}

+ (NSString *) longitude
{
    return [[[self sharedInstance] instanceLocationData] objectForKey:@"lon"];
}

+ (NSDictionary *) customUserInformation
{
    return [[self sharedInstance] instanceCustomUserInformation];
}

+ (NSString *) udid
{
    return [NWOpenUDID value];
}

+ (NSString *) version
{
    return kNWSDKVersion;
}

///////////////////////////////////////
// This is the inbox-specific part
// In the interest of keeping this all together, it is included in the same Neemware class

#pragma mark - Inbox Related Accessors

// Accessors
+ (NSString *) inboxUnreadCount
{
    // Return the count or, if '0', nil -- if we return nil then any badge displayed will disappear instead of displaying '0'
    NSString *unreadCount = [[NWContentDataStore sharedInstance] unreadContentCount];
    if ([unreadCount isEqualToString:@"0"])
        return nil;
    else
        return [[NWContentDataStore sharedInstance] unreadContentCount];
}

#pragma mark - Inbox Related Methods

// Methods
+ (void) displayInboxFrom:(UIViewController *)vc
{
    if (!sharedInstance.instanceInboxIsLoaded)
    {
        NSLog(@"Inbox is not loaded yet...");
        [sharedInstance updateData];
    }
    

    NWInboxTableViewController *inboxTVC = [[NWInboxTableViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:inboxTVC];
    [sharedInstance notifyServerThatInboxWasViewed];
    
    [vc presentModalViewController:navController animated:YES];
}

- (void)updateData
{
    NSLog(@"Loading inbox...");
    [[NWContentDataStore sharedInstance] updateContentData];
    [self setInstanceInboxIsLoaded:YES];
}

-(void)notifyServerThatInboxWasViewed
{
    NSString *urlString = @"http://api.neemware.com/content/read";
    urlString = [urlString stringByAppendingFormat:@"?api_key=%@&did=%@&v=%@&d_model=%@", [Neemware apiKey], [Neemware udid], [Neemware version], @"abc"];
    
    if ([Neemware location])
        urlString =[urlString stringByAppendingFormat:@"&lat=%@&lng=%@", [Neemware latitude], [Neemware longitude]];
    
    NSURLRequest *ping = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    
    // Async ping, we don't care to know results so don't set delegate or anything
    [[NSURLConnection alloc] initWithRequest:ping delegate:nil];
}

#pragma mark - Banner related methods
+(void)showBannerInViewController:(UIViewController *)vController
{
    // If short method is used, delay 2 seconds
    [self showBannerInViewController:vController withDelay:2];
}

+(void)showBannerInViewController:(UIViewController *)vController withDelay:(NSInteger)delay
{
    // If there is a bannerView on this view controller, then tell it that its ok to display
    if ([NWBannerView bannerViewInViewController:vController])
    {
        NWBannerView *bView = [NWBannerView bannerViewInViewController:vController];
        [NSTimer scheduledTimerWithTimeInterval:delay target:bView selector:@selector(showBanner) userInfo:nil repeats:NO];
    }
    
    // Otherwise, just add the bannerView to the vc and it will listen for notifications
    else
    {
        NWBannerView *bannerView = [[NWBannerView alloc] initWithController:vController];
        [vController.view addSubview:bannerView];
        bannerView = nil;
    }
}

@end
