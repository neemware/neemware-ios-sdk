//
//  NWBannerView.h
//  NWSDKTestApp
//
//  Created by Erik Stromlund (Neemware) on 8/10/12.
//  Copyright (c) 2013 Neemware, Inc. All rights reserved.
//

@class NWContentData;
#import <Foundation/Foundation.h>

@interface NWBannerView : UIView {
    UIViewController        *_currentViewController;
    UIButton                *_bannerDisplay;
    UIImageView             *_imgView;
    NWContentData           *_contentData;
    BOOL                     _bannerOnScreen;
}

@property (nonatomic, strong) UIButton          *bannerDisplay;
@property (nonatomic, strong) UIImageView       *imgView;
@property (nonatomic, strong) NWContentData     *contentData;
@property (nonatomic, strong) UIViewController  *currentViewController;
@property (nonatomic)         BOOL              bannerOnScreen;

// For displaying the webview
@property (nonatomic) UIModalPresentationStyle ps;
@property (nonatomic) UIModalTransitionStyle ts;
@property (nonatomic) BOOL animated;

// Searches the UIViewController |vc| and finds/returns any banners that have been added to |vc|'s view
+(NWBannerView *)bannerViewInViewController:(UIViewController *)vc;

// Designated init method for setting display options
-(id)initWithController:(UIViewController *)vController
        modalPresentationStyle:(UIModalPresentationStyle)ps
          modalTransitionStyle:(UIModalTransitionStyle)ts
                     animation:(BOOL)animated;

// Show the banner
-(void)showBanner;

@end
