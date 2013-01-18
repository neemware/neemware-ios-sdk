//
//  NWWebViewController.h
//  NWSDKTestApp
//
//  Created by Erik Stromlund (Neemware) on 8/10/12.
//  Copyright (c) 2013 Neemware, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@class NWContentData;

@interface NWWebViewController : UIViewController <UIWebViewDelegate>
{
    UIWebView*                  _webView;
    NWContentData*              _currentContent;
    UIActivityIndicatorView*    _activityInd;
    BOOL                        newLoad;
    
}

@property (nonatomic)           BOOL                        formIsSubmitted;
@property (strong, nonatomic)   UIWebView                   *webView;
@property (strong, nonatomic)   NWContentData               *currentContent;
@property (strong, nonatomic)   UIActivityIndicatorView     *activityInd;
@property (strong, nonatomic)   UIToolbar                   *tBar;

-(id)initWithURL:(NSString *)url;
-(id)initWithContent:(NWContentData *)content;

@end
