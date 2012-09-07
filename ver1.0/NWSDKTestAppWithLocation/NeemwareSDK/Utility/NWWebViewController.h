//
//  NWWebViewController.h
//  NWSDKTestApp
//
//  Created by Erik Stromlund (neemware) on 8/10/12.
//  Copyright (c) 2012 Neemware, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@class NWContentData;

@interface NWWebViewController : UIViewController <UIWebViewDelegate>
{
    UIWebView*                  _webView;
    NWContentData*              _currentContent;
    UIActivityIndicatorView*    _activityInd;
    
}

@property (nonatomic)           BOOL                        formIsSubmitted;
@property (strong, nonatomic)   UIWebView                   *webView;
@property (strong, nonatomic)   NWContentData               *currentContent;
@property (strong, nonatomic)   UIActivityIndicatorView     *activityInd;

-(id)initWithURL:(NSString *)url;
-(id)initWithContent:(NWContentData *)content;

@end
