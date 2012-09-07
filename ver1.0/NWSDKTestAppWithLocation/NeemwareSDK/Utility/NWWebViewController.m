//
//  NWWebViewController.m
//  NWSDKTestApp
//
//  Created by Erik Stromlund (neemware) on 8/10/12.
//  Copyright (c) 2012 Neemware, Inc. All rights reserved.
//

#import "NWWebViewController.h"
#import "NWContentDataStore.h"
#import "NWContentData.h"

@interface NWWebViewController ()

@end

@implementation NWWebViewController

@synthesize webView=_webView;
@synthesize currentContent = _currentContent;
@synthesize formIsSubmitted;
@synthesize activityInd = _activityInd;

- (id)initWithURL:(NSString *)url
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
//        NSLog(@"initiating webview with URL: %@", url);
        // Initialize a UIWebView
        self.webView = [[UIWebView alloc] init];
        
        // Set this instance as the delegate (delegate methods are below)
        [self.webView setDelegate:self];
        
        // Reset the formIsSubmitted boolean
        [self setFormIsSubmitted:NO];
        
        // Load the URL in the webview
        NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadRevalidatingCacheData timeoutInterval:10];
        [self.webView loadRequest:urlRequest];
        
        // Set the webview as this viewController's view
        [self setView:self.webView];
    }
    return self;
}

- (id)initWithContent:(NWContentData *)content
{
    _currentContent = content;
//    NSLog(@"initiating webView with content: %@", self.currentContent);
    self = [self initWithURL:_currentContent.contentURL];
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.activityInd)
    {
        // Setup activity indicator
        self.activityInd = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.activityInd.frame = CGRectMake(self.view.frame.size.width * 0.5,self.view.frame.size.height * 0.5, 20, 20);
        self.activityInd.hidesWhenStopped = YES;
        [self.view addSubview:self.activityInd];
    }
//    [self.activityInd startAnimating];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.activityInd stopAnimating];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

#pragma mark - UIWebView Delegate Methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    // If the page is loading because we just submitted a form (i.e. answered a question), then toggle formIsSubmitted to YES
    if (navigationType == UIWebViewNavigationTypeFormSubmitted) {
        [self setFormIsSubmitted:YES];
    } else
    {
        // We want all hyperlinks to open in Safari (unless it is the above case of someone submitting an answer to a question)
        if ( navigationType == UIWebViewNavigationTypeLinkClicked ) {
            [[UIApplication sharedApplication] openURL:[request URL]];
            return NO;
        }
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.activityInd startAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.activityInd stopAnimating];
    
    // If we are done loading because a question was answered, close the webView
    if (self.formIsSubmitted) {
        NSLog(@"Form is submitted...currentContent = %@", self.currentContent);
        [[NWContentDataStore sharedInstance] userAnsweredQuestion:self.currentContent];
        [self dismissThisView];
    } else {
        // Otherwise
        // Add the 'X'/close button to the webview in upper right corner after content has loaded
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button addTarget:self
                   action:@selector(dismissThisView)
         forControlEvents:UIControlEventTouchUpInside];
        
        UIImage *img = [UIImage imageNamed:@"close-icon.png"];
        [button setBackgroundImage:img forState:UIControlStateNormal];
        button.frame = CGRectMake(320-23, 3, 20, 20);
        [webView addSubview:button];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    // load error, hide the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.activityInd stopAnimating];
    
    // report the error inside the webview
    NSString* errorString = [NSString stringWithFormat:
                             @"<html><center><font size=+5 color='red'>An error occurred:<br>%@</font></center></html>",
                             error.localizedDescription];
    [webView loadHTMLString:errorString baseURL:nil];
}

- (void)dismissThisView
{
    [self dismissModalViewControllerAnimated:YES];
}


@end
