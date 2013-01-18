//
//  NWBannerView.m
//  NWSDKTestApp
//
//  Created by Erik Stromlund (Neemware) on 8/10/12.
//  Copyright (c) 2013 Neemware, Inc. All rights reserved.
//

#import "NWBannerView.h"
#import "NWContentData.h"
#import "NWContentDataStore.h"
#import "NWWebViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation NWBannerView

static const CGFloat    kCornerRadius           = 5;
static const NSInteger  kBufferFromScreenEdge   = 1;
static const NSInteger  kBannerHeight           = 50;

@synthesize contentData =           _contentData;
@synthesize currentViewController = _currentViewController;
@synthesize bannerOnScreen =        _bannerOnScreen;
@synthesize imgView =               _imgView;

#pragma mark - Designated initializer
- (id)initWithController:(UIViewController *)vController
        modalPresentationStyle:(UIModalPresentationStyle)ps
          modalTransitionStyle:(UIModalTransitionStyle)ts
                     animation:(BOOL)animated
{
    CGRect bannerFrame = CGRectZero;
    NSInteger frameHeight = vController.view.frame.size.height;
    NSInteger frameWidth = vController.view.frame.size.width;
    
    // Correct for bug that occurs when user is scrolling and the banner is added to the view
    // the height may not actually represent the bottom of the screen in that case
    //
    // Adjust by adding contentOffset.y (if available) to height of view
    if ([vController.view respondsToSelector:@selector(contentOffset)]) {
        frameHeight = vController.view.frame.size.height + ((UIScrollView *)vController.view).contentOffset.y;
    }
    
    // Shrink the frame by kBufferFromScreenEdge to add buffer/border around it
    bannerFrame = CGRectMake(0.0 + kBufferFromScreenEdge, frameHeight, frameWidth - 2 * kBufferFromScreenEdge, kBannerHeight);
    
    // Put the banner on top of everything
    self.layer.zPosition = 9999;
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    if (self = [self initWithController:vController andFrame:bannerFrame])
    {
        self.animated = animated;
        self.ps = ps;
        self.ts = ts;
    }
    return self;
}

#pragma mark - Superclass initializer

- (id)initWithController:(UIViewController *)vController andFrame:(CGRect)frm
{
    if (self = [super initWithFrame:frm])
    {
        [self setCurrentViewController:vController];
        
        // Setup observers to show/hide banner when view appears or disappears
        //(viewDidAppear/viewWillDisappear do not get called when app becomes active or goes to background)
        //
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showBanner) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideBanner) name:UIApplicationDidEnterBackgroundNotification object:nil];
        
        // Setup observers that will be triggered when new content is received or old content is read
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newBannerContentReceived:) name:@"kNWNewBannerContentAvailable"  object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideBannerWithContent:)    name:@"kNWContentWasReadNotification" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceRotated) name:UIDeviceOrientationDidChangeNotification object:nil];
        
    }
    return self;
}

#pragma mark - Banner Display/UI Setup

- (UIButton *)bannerDisplay
{
    if (!_bannerDisplay) {
        // Putting this here because it is a good spot that is called after the view is initialized
        // but before the banner is displayed.  Can't add it to initialize b/c superview doesn't exist at that point
        //
        // Listen to KVO for contentOffset of superview
        if (self.superview)
            [self.superview addObserver:self forKeyPath:@"contentOffset" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionPrior | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionNew) context:NULL];

        CGRect bannerFrame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        _bannerDisplay.frame = bannerFrame;
        _bannerDisplay = [[UIButton alloc] initWithFrame:bannerFrame];
        _bannerDisplay.layer.cornerRadius = kCornerRadius;
        _bannerDisplay.backgroundColor = [UIColor colorWithRed:(25.0/255.0) green:(25.0/255.0) blue:(25.0/255.0) alpha:1.0];
        
        if (!self.imgView)
        {
            // Banner frame is 50 tall and full-screen wide
            // So set the imageView to be 24x24, then to center it vertically, (50-24)/2 = 13 unit offset
            self.imgView = [[UIImageView alloc] initWithFrame:CGRectMake(13,13,24,24)];
            self.imgView.backgroundColor = [UIColor clearColor];
            [_bannerDisplay addSubview:self.imgView];
        }
        
        _bannerDisplay.titleLabel.frame = CGRectMake(bannerFrame.origin.x,
                                                     bannerFrame.origin.y,
                                                     bannerFrame.size.width-50,
                                                     bannerFrame.size.height);
        
        // Push the content (titleLabel) up to the left side of the button
        _bannerDisplay.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        
        // Add padding on the left
        [_bannerDisplay setTitleEdgeInsets:UIEdgeInsetsMake(0, 60, 0, 0)];
        
        _bannerDisplay.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
        [_bannerDisplay setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        _bannerDisplay.titleLabel.textAlignment = UITextAlignmentLeft;
        _bannerDisplay.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
        _bannerDisplay.titleLabel.numberOfLines = 2;

        _bannerDisplay.showsTouchWhenHighlighted = YES;
        [_bannerDisplay addTarget:self action:@selector(bannerTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _bannerDisplay;
}

- (void)setupBannerForDisplay
{
    // display title if there is one, otherwise display body text
    if (_contentData.contentSubject)
        [self.bannerDisplay setTitle:_contentData.contentSubject forState:UIControlStateNormal];
    else
        [self.bannerDisplay setTitle:_contentData.contentBody forState:UIControlStateNormal];
    [self removeBannerFromSubviews];
    
    if (_contentData.contentIconURL)
    {
        // Get a dispatch queue
        dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        // This will start the image loading in bg
        dispatch_async(concurrentQueue, ^{
            NSString *url = _contentData.contentIconURL;
            if (![url hasPrefix:@"http://"])
                url = [NSString stringWithFormat:@"http://%@", _contentData.contentIconURL];
            NSData *image = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:10] returningResponse:nil error:nil];
            
            // This will set the image when loading is finished (using main queue)
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imgView.image = [UIImage imageWithData:image];
            });
        });
    }
    
    [self addSubview:[self bannerDisplay]];
}

// Resets the banner's position to be just off the bottom of the screen
- (void)setBannerOffBottomOfScreen
{
    CGRect bannerFrame = CGRectZero;
    NSInteger frameHeight = self.superview.frame.size.height;
    NSInteger frameWidth = self.superview.frame.size.width;
    
    // Try and correct for bug that occurs when user is scrolling and the banner is added to the view
    // the height may not actually represent the bottom of the screen in that case
    if ([self.superview respondsToSelector:@selector(contentOffset)]) {
        frameHeight = frameHeight + ((UIScrollView *)self.superview).contentOffset.y;
    }
    
    // Shrink the frame by kBufferFromScreenEdge to add buffer/border around it
    bannerFrame = CGRectMake(0.0 + kBufferFromScreenEdge, frameHeight, frameWidth - 2 * kBufferFromScreenEdge, 50);
    self.frame = bannerFrame;
}

#pragma mark - Action Methods

- (void)bannerTapped
{
    // Initialize a webviewcontroller with the contentURL
    NWWebViewController *webController = [[NWWebViewController alloc] initWithContent:_contentData];
    
    // Mark this content as read -- this will also hide and delete the banner through the callback/observer that is fired off
    [[NWContentDataStore sharedInstance] userReadContent:_contentData];
    
    // And, pop it up on the screen using the settings that were set in the designated initializer
    [webController setModalPresentationStyle:self.ps];
    [webController setModalTransitionStyle:self.ts];
    
    // presentViewController only works for iOS5 and above
    if ([self.currentViewController respondsToSelector:@selector(presentViewController:animated:completion:)])
        [self.currentViewController presentViewController:webController animated:self.animated completion:nil];
    else
        [self.currentViewController presentModalViewController:webController animated:self.animated];
}

- (void)showBanner
{    
    // Make sure banner actually is just off bottom of screen
    [self setBannerOffBottomOfScreen];

    _contentData = [[NWContentDataStore sharedInstance] nextObjectToDisplayInBanner];
    
    [self setupBannerForDisplay];
    
    // Only show something if:
    // 1) there is something to show
    // 2) the correct viewController is on the screen
    // 3) and there isn't another banner displayed
    if (_contentData != nil && _bannerDisplay != nil && [self vcOnScreen] && !self.bannerOnScreen)
    {
        [self setBannerOnScreen:YES];
        
        // Slide the banner up from the bottom
        CGRect newFrame = CGRectOffset(self.frame, 0, -self.frame.size.height - kBufferFromScreenEdge);
        
        // Use block animations if it is supported (iOS 4.0 and later)
        if ([UIView respondsToSelector:@selector(animateWithDuration:animations:)]) {
            [UIView animateWithDuration:0.5
                             animations:^{
                                self.frame = newFrame;
                             }
                             completion:nil];
        }
        // If block animations are not supported, use the old way of animations
        else {
            [UIView beginAnimations:@"Animate banner appearance" context:NULL];
            self.frame = newFrame;
            [UIView commitAnimations];
        }
        
        // Hide the banner after 5 seconds
        [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(hideBanner) userInfo:nil repeats:NO];
    }
}

- (void)hideBanner
{
    // Only hide the banner if it is onscreen
    // Otherwise, the banner will keep moving down (off the screen) by frame-height
    // But we want it to stay only one frame-height below
    if (self.bannerOnScreen)
    {
        // Assumes the banner view is just above the bottom of the screen
        // Slide the banner back down
        CGRect newFrame = CGRectOffset(self.frame, 0, self.frame.size.height + kBufferFromScreenEdge);
        
        // Use block animations if it is supported (iOS 4.0 and later)
        if ([UIView respondsToSelector:@selector(animateWithDuration:animations:)]) {
            [UIView animateWithDuration:0.5
                             animations:^{
                                self.frame = newFrame;
                             }
                             completion:nil];
        }
        // If block animations are not supported, use the old way of animations
        else {
            [UIView beginAnimations:@"Animate banner appearance" context:NULL];
            self.frame = newFrame;
            [UIView commitAnimations];
        }
    }
    _contentData = nil;
    [self setBannerOnScreen:NO];
}

#pragma mark - Class utility methods

// This method looks for and returns the NWBannerView contained in a given view controller
// Or returns nil if there is none
// Assumes that only one banner view is there (which should be true) and returns the first found
+ (NWBannerView *)bannerViewInViewController:(UIViewController *)vc
{
    for (UIView *view in vc.view.subviews)
    {
        if ([view isKindOfClass:[NWBannerView class]])
            return (NWBannerView *)view;
    }
    return nil;
}

- (BOOL)vcOnScreen
{
    // Check that the view controller is on the screen and doesn't have a modal displayed
    if (self.currentViewController.isViewLoaded && self.currentViewController.view.window && !self.currentViewController.presentedViewController)
        return YES;
    return NO;
}

- (void)removeBannerFromSubviews
{
    for (UIView *view in self.subviews)
    {
        if ([view isKindOfClass:[NWBannerView class]])
            [view removeFromSuperview];
    }
}

#pragma mark - Notification-Triggered Methods

// This is triggered by kNWNewBannerContentAvailable
- (void)newBannerContentReceived:(NSNotification *)not
{
    // Don't display it if there is already another banner being displayed on this screen
    if (self.bannerOnScreen || _contentData)
        return;
    
    // If this view controller is currently visible, and there is no other banner displayed,
    // then show the new banner
    if ([self vcOnScreen] && !self.bannerOnScreen)
        [self showBanner];
}

// This is triggered when content is marked read somewhere
// and makes sure that those banners aren't displayed again
- (void)hideBannerWithContent:(NSNotification *)not
{
    NSString *contentType = [not.userInfo objectForKey:@"content_type"];
    NSString *contentID = [not.userInfo objectForKey:@"content_id"];
    
    // Check if this banner's contentData has same type and id as that which is to be removed
    // If they both match, then remove the banner and set this banner's _contentData to nil
    if ([_contentData.contentType isEqualToString:contentType] &&
        [_contentData.contentID isEqualToString:contentID])
    {
        _contentData = nil;
        
        // Hide the banner if it was on screen
        if (self.bannerOnScreen)
            [self hideBanner];
    }
}

// This is triggered when the device is rotated
- (void)deviceRotated
{
    [self hideBanner];
    [self setBannerOffBottomOfScreen];
}

#pragma mark - KVO Observation Delegate Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // Receives contentOffset changes, and adjusts the banner to go up/down that much
    // This keeps the banner in one spot (the bottom of the screen)
    if([keyPath isEqualToString:@"contentOffset"]) {
        CGRect oldFrame = CGRectNull;
        CGRect newFrame = CGRectNull;
        
        if([change objectForKey:@"old"] != [NSNull null])
            oldFrame = [[change objectForKey:@"old"] CGRectValue];
        
        if([object valueForKeyPath:keyPath] != [NSNull null])
            newFrame = [[object valueForKeyPath:keyPath] CGRectValue];
        
        // If the banner tries to move, adjust it back by that much
        self.frame = CGRectMake(self.frame.origin.x,
                                self.frame.origin.y + (newFrame.origin.y - oldFrame.origin.y),
                                self.frame.size.width,
                                self.frame.size.height);
    }
}

#pragma mark - Cleanup

-(void)dealloc
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.superview removeObserver:self forKeyPath:@"contentOffset"];
}
@end
