//
//  NWBannerView.m
//  NWSDKTestApp
//
//  Created by Erik Stromlund (neemware) on 8/10/12.
//  Copyright (c) 2012 Neemware, Inc. All rights reserved.
//

#import "NWBannerView.h"
#import "NWContentData.h"
#import "NWContentDataStore.h"
#import "NWWebViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation NWBannerView

static const CGFloat    kCornerRadius           = 5;
static const NSInteger  kBufferFromScreenEdge   = 1;

@synthesize contentData =           _contentData;
@synthesize currentViewController = _currentViewController;
@synthesize bannerOnScreen =        _bannerOnScreen;

-(id)initWithController:(UIViewController *)vController andFrame:(CGRect)frm
{
    if (self = [super initWithFrame:frm])
    {
        [self setCurrentViewController:vController];
        
        // Setup observers so content information gets updated
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showBanner) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideBanner) name:UIApplicationDidEnterBackgroundNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newBannerContentReceived:) name:@"kNWNewBannerContentAvailable"  object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideBannerWithContent:)    name:@"kNWContentWasReadNotification" object:nil];
    }
    return self;
}

-(id)initWithController:(UIViewController *)vController
{
    CGRect bannerFrame = CGRectZero;
    NSInteger frameHeight = vController.view.frame.size.height;
        
    // Shrink the frame by kBufferFromScreenEdge to add buffer/border around it
    bannerFrame = CGRectMake(0.0 + kBufferFromScreenEdge, frameHeight, 320 - 2 * kBufferFromScreenEdge, 50);
    
    if (self = [self initWithController:vController andFrame:bannerFrame])
    {
        // Don't need to do anything here at this point...
    }
    return self;
}

-(void)newBannerContentReceived:(NSNotification *)not
{
    NSLog(@"newBannerContentReceived!");
    // Don't display it if there is already another banner being displayed on this screen
    if (self.bannerOnScreen || _contentData)
    {
        NSLog(@"ignoring new banner reqeust - another is already on screen");
        return;
    }

    // If this view controller is currently visible,  and there is no other banner displayed,
    // then show the new banner
    if ([self vcOnScreen] && !self.bannerOnScreen)
    {
        NSLog(@"newContent received, and displaying the banner");
        [self showBanner];
    }
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
        NSLog(@"Hide banner notice received - contentData set to nil");
        
        // Hide the banner if it was on screen
        if (self.bannerOnScreen)
            [self hideBanner];
    }
}

-(void)setupBannerForDisplay
{
    // display title if there is one, otherwise display body text
    if (_contentData.contentSubject)
        [self.bannerDisplay setTitle:_contentData.contentSubject forState:UIControlStateNormal];
    else
        [self.bannerDisplay setTitle:_contentData.contentBody forState:UIControlStateNormal];
    [self removeBannerFromSubviews];
    [self addSubview:[self bannerDisplay]];
}

-(void)removeBannerFromSubviews
{
    for (UIView *view in self.subviews)
    {
        if ([view isKindOfClass:[NWBannerView class]])
            [view removeFromSuperview];
    }
}

- (UIButton *)bannerDisplay
{
    if (!_bannerDisplay) {
        CGRect bannerFrame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        _bannerDisplay = [[UIButton alloc] initWithFrame:bannerFrame];
        _bannerDisplay.layer.cornerRadius = kCornerRadius;
        _bannerDisplay.backgroundColor = [UIColor colorWithRed:(25.0/255.0) green:(25.0/255.0) blue:(25.0/255.0) alpha:1.0];
        _bannerDisplay.frame = bannerFrame;
        
        // Push the content (titleLabel) up to the left side of the button
        _bannerDisplay.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        
        // Add padding on the left
        [_bannerDisplay setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
        
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

- (void)bannerTapped
{
    // Initialize a webviewcontroller with the contentURL
    NWWebViewController *webController = [[NWWebViewController alloc] initWithContent:_contentData];
    
    // And, pop it up on the screen, modally
    [self.currentViewController presentModalViewController:webController animated:YES];
    
    // Mark this content as read -- this will also hide and delete the banner through the callback/observer that is fired off
    [[NWContentDataStore sharedInstance] userReadContent:_contentData];
}

- (void)showBanner
{
    // Get the content for the next banner
    _contentData = [[NWContentDataStore sharedInstance] nextObjectToDisplayInBanner];
    
    // Configure the banner with that content
    [self setupBannerForDisplay];
    
    // Only show something if there is something to show and the right viewController is on the screen and there isn't another banner displayed
    NSLog(@"contentdata: %@, bannerdisplay: %@, onscreen: %d, banneronscreen: %d", _contentData, _bannerDisplay, [self vcOnScreen], self.bannerOnScreen);
    if (_contentData != nil && _bannerDisplay != nil && [self vcOnScreen] && !self.bannerOnScreen)
    {
        [self setBannerOnScreen:YES];
        
        // Assumes the banner view is just off the bottom of the screen
        // Slide the banner up from the bottom
        CGRect newFrame = CGRectOffset(self.frame, 0, -self.frame.size.height - kBufferFromScreenEdge);
        
        // Use block animations if it is supported (iOS 4.0 and later)
        if ([UIView respondsToSelector:@selector(animateWithDuration:animations:)]) {
            [UIView animateWithDuration:0.5 animations:^{
                self.frame = newFrame;
            }];
        }
        // If block animations are not supported, use the old way of animations
        else {
            [UIView beginAnimations:@"Animate banner appearance" context:NULL];
            self.frame = newFrame;
            [UIView commitAnimations];
        }
        NSLog(@"Showing banner");
        [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(hideBanner) userInfo:nil repeats:NO];
    } else
    {
        NSLog(@"Criteria not met - Did not show banner");
    }
}

-(void)hideBanner
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
            [UIView animateWithDuration:0.5 animations:^{
                self.frame = newFrame;
            }];
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

// This method looks for and returns the NWBannerView contained in a given view controller
// Or returns nil if there is none
// Assumes that only one banner view is there (which should be true) and returns the first found
+(NWBannerView *)bannerViewInViewController:(UIViewController *)vc
{
    for (UIView *view in vc.view.subviews)
    {
        if ([view isKindOfClass:[NWBannerView class]])
            return (NWBannerView *)view;
    }
    return nil;
}

-(BOOL)vcOnScreen
{
    // Check that the view controller is on the screen and doesn't have a modal displayed
    if (self.currentViewController.isViewLoaded && self.currentViewController.view.window && !self.currentViewController.presentedViewController)
        return YES;
    return NO;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
