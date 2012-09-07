//
//  NWBannerView.h
//  NWSDKTestApp
//
//  Created by Erik Stromlund (neemware) on 8/10/12.
//  Copyright (c) 2012 Neemware, Inc. All rights reserved.
//

@class NWContentData;
#import <Foundation/Foundation.h>

@interface NWBannerView : UIView {
    UIViewController        *_currentViewController;
    UIButton                *_bannerDisplay;
    NWContentData           *_contentData;
    BOOL                     _bannerOnScreen;
}

@property (nonatomic, strong) UIButton          *bannerDisplay;
@property (nonatomic, strong) NWContentData     *contentData;
@property (nonatomic, strong) UIViewController  *currentViewController;
@property (nonatomic)         BOOL              bannerOnScreen;

+(NWBannerView *)bannerViewInViewController:(UIViewController *)vc;

//-(id)initWithController:(UIViewController *)vController andFrame:(CGRect)frm;
-(id)initWithController:(UIViewController *)vController;


-(void)showBanner;

@end
