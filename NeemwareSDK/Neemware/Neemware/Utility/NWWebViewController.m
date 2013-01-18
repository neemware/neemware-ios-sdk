//
//  NWWebViewController.m
//  NWSDKTestApp
//
//  Created by Erik Stromlund (Neemware) on 8/10/12.
//  Copyright (c) 2013 Neemware, Inc. All rights reserved.
//

#import "NWWebViewController.h"
#import "NWContentDataStore.h"
#import "NWContentData.h"
#import "Neemware.h"

@implementation NWWebViewController

@synthesize webView=_webView;
@synthesize currentContent = _currentContent;
@synthesize formIsSubmitted;
@synthesize activityInd = _activityInd;

#pragma mark - Class Setup

// Either initializer will work, depending on if you want to
// use a URL or get the URL from a NWContentData object
- (id)initWithURL:(NSString *)url
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        
        // Initialize a UIWebView
        self.webView = [[UIWebView alloc] init];
        
        // Set this instance as the delegate (delegate methods are below)
        [self.webView setDelegate:self];
        
        // Reset the formIsSubmitted boolean
        [self setFormIsSubmitted:NO];
        
        // Load the URL in the webview
        NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:10];
        [self.webView loadRequest:urlRequest];
        
        [self.webView setScalesPageToFit:YES];

        // Set the webview as this viewController's view
        [self setView:self.webView];
        
        newLoad = YES;
    }
    return self;
}

- (id)initWithContent:(NWContentData *)content
{
    _currentContent = content;
    
    // Generate URL
    // Start with the content-specific 'show' url
    NSString *urlString = _currentContent.contentURL;
    
    // Add our parameters
    NSString *model = [UIDevice currentDevice].model;
    NSString *os    = [UIDevice currentDevice].systemName;
    NSString *osv   = [UIDevice currentDevice].systemVersion;
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    
    urlString = [urlString stringByAppendingFormat:@"?api_key=%@&did=%@&v=%@&d_model=%@&d_os=%@&d_osv=%@&app_v=%@", [Neemware apiKey], [Neemware udid], [Neemware version], model, os, osv, appVersion];
    if ([Neemware location])
        urlString =[urlString stringByAppendingFormat:@"&latitude=%@&longitude=%@", [Neemware latitude], [Neemware longitude]];
    
    self = [self initWithURL:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    return self;
}

#pragma mark - View Lifecycle Methods

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setToolbarConfigForOrientation:[[UIDevice currentDevice] orientation]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Handle coming back after leaving for appstore
    if (!newLoad)
        [self dismissThisView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.activityInd stopAnimating];
}

#pragma mark - Rotation Methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self setToolbarConfigForOrientation:toInterfaceOrientation];
}

- (void)setToolbarConfigForOrientation:(UIInterfaceOrientation)orientation
{
    [self.tBar removeFromSuperview];
    self.tBar = nil;
    NSInteger tBarHeight = 0;
    
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        tBarHeight = 32;
    else
        tBarHeight = 44;
    
    self.tBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0,self.view.bounds.size.height-tBarHeight,self.view.bounds.size.width,tBarHeight)];
    self.tBar.barStyle = UIBarStyleBlackTranslucent;
    [self.tBar sizeToFit];
    
    //Add button
    UIBarButtonItem *systemItem1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissThisView)];
    
    UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                              target:nil
                                                                              action:nil];
    NSArray *items = [NSArray arrayWithObjects: systemItem1, flexItem, nil];
    [self.tBar setItems:items];
    [self.view addSubview:self.tBar];
}

#pragma mark - UIWebView Delegate Methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    // Redirect an itunes link to safari so it is better handled
    if( [request.URL.host hasSuffix:@"itunes.apple.com"])
    {
        newLoad = NO;
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    
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
    if (!self.activityInd)
    {
        // Setup activity indicator
        self.activityInd = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.activityInd.frame = CGRectMake(self.view.frame.size.width * 0.5,(self.view.frame.size.height -44) * 0.5, 20, 20);
        self.activityInd.hidesWhenStopped = YES;
        [self.view addSubview:self.activityInd];
    }
    [self.activityInd startAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.activityInd stopAnimating];
    
    // If we are done loading because a question was answered, close the webView
    if (self.formIsSubmitted) {
        [[NWContentDataStore sharedInstance] userAnsweredQuestion:self.currentContent];
        [self dismissThisView];
    } else
    {
        // Handle a page that will be shown
        
        // Reset any device-width meta tag on the html page to fit the device being used
        NSString* js =
        [NSString stringWithFormat:@"var meta = document.createElement('meta'); "
        "meta.setAttribute( 'name', 'viewport' ); "
        "meta.setAttribute( 'content', 'width = %f' ); "
         "document.getElementsByTagName('head')[0].appendChild(meta)", webView.bounds.size.width];
        [webView stringByEvaluatingJavaScriptFromString: js];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    // load error, hide the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.activityInd stopAnimating];
    
    // report the error inside the webview
    NSString* errorString = @"<html><center>Sorry, your message could not be opened.  Please try again later.</center></html>";
    [webView loadHTMLString:errorString baseURL:nil];
}

#pragma mark - Dismiss Action
- (void)dismissThisView
{
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)])
        [self dismissViewControllerAnimated:YES completion:nil];
    else
        [self dismissModalViewControllerAnimated:YES];
}


@end
