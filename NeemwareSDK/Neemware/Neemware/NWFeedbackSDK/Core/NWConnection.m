//
//  NWConnection.m
//
//  Created by Puru Choudhary on 12/12/11.
//  Modified by Erik Stromlund on 12/15/2012
//  Copyright (c) 2013 Neemware. All rights reserved.
//

#import "NWConnection.h"
#import "NWFeedbackConstants.h"
#import "NWObject.h"
#import "Neemware.h"
#import "NW_JSONKit.h"
#import "NWOpenUDID.h"

static NSString *kNWBaseAPIURL = @"https://api.neemware.com/1";

@interface NWConnection () {
@private
    NSString       *_applicationKey;
    NSMutableArray *_objectsToSend;
}
@property (nonatomic, readonly) NSString *applicationKey;
@property (nonatomic, strong) NSMutableArray *objectsToSend;
@end

@implementation NWConnection

# pragma mark - Accessors
@synthesize delegate = _delegate;
@synthesize applicationKey = _applicationKey;
@synthesize objectsToSend = _objectsToSend;
@synthesize responseData = _responseData;

- (NSMutableArray *)objectsToSend
{
    if (!_objectsToSend) {
        _objectsToSend = [[NSMutableArray alloc] init];
    }
    return _objectsToSend;
}

# pragma mark - Setup and delloc
- (id)initWithApplicationKey:(NSString *)applicationKey
{
    self = [super init];
    if (self) {
        _applicationKey = applicationKey;
    }
    return self;
}

# pragma mark - Data handling

- (BOOL)addObjectToSend:(NWObject *)object
{
    // Check if the object is of NWObject type and return false if it is not
    if (![object isKindOfClass:[NWObject class]]) return false;
    
    [self.objectsToSend addObject:object];
    return true;
}

- (NSArray *)objectsWaitingToBeSent
{
    return self.objectsToSend;
}

- (void)sendObjects
{
    for (NWObject *object in self.objectsToSend) {
        NWDLog(@"sobject: %@, class: %@", object, [object class]);
        NSString *resourceURLString = [kNWBaseAPIURL stringByAppendingString:object.resourcePath];
        NSURL *resourceURL = [NSURL URLWithString:resourceURLString];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:resourceURL];
        
        // Create the post body
        [request setHTTPMethod:@"POST"];
        [request setValue:@"NWConnection" forHTTPHeaderField:@"User-Agent"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        // Device ID
        NSDictionary *device_id = [NSDictionary dictionaryWithObject:[NWOpenUDID value] forKey:@"device_id"];
        
        // Api Key
        NSDictionary *api_key = [NSDictionary dictionaryWithObject:self.applicationKey forKey:@"api_key"];
        
        // Model, etc.
        // Modify the URL to include our parameters
        NSString *model = [UIDevice currentDevice].model;
        NSString *os    = [UIDevice currentDevice].systemName;
        NSString *osv   = [UIDevice currentDevice].systemVersion;
        NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
        
        NSDictionary *versionDict = [NSDictionary dictionaryWithObject:[Neemware version] forKey:@"v"];
        NSDictionary *modelDict = [NSDictionary dictionaryWithObject:model forKey:@"d_model"];
        NSDictionary *osDict = [NSDictionary dictionaryWithObject:os forKey:@"d_os"];
        NSDictionary *osvDict = [NSDictionary dictionaryWithObject:osv forKey:@"d_osv"];
        NSDictionary *appVDict = [NSDictionary dictionaryWithObject:appVersion forKey:@"app_v"];

        // Request params dict
        NSMutableDictionary *requestBody = [[NSMutableDictionary alloc] initWithDictionary:device_id];
        [requestBody addEntriesFromDictionary:api_key];
        [requestBody addEntriesFromDictionary:versionDict];
        [requestBody addEntriesFromDictionary:modelDict];
        [requestBody addEntriesFromDictionary:osDict];
        [requestBody addEntriesFromDictionary:osvDict];
        [requestBody addEntriesFromDictionary:appVDict];
        
        // Add object to be sent
        [requestBody addEntriesFromDictionary:[object dataInDictionary]];
        
        // Convert to JSON
        NSString *jsonRequestBody = [requestBody JSONString];
        
        // Convert to NSData
        NSData *requestData = [NSData dataWithBytes:[jsonRequestBody UTF8String] length:[jsonRequestBody length]];
        
        [request setValue:[NSString stringWithFormat:@"%d", [requestData length]] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:requestData];
        
        // Initiate request
        
        NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
        if (connection)
            _responseData = [NSMutableData data];
    }
    
    [self.objectsToSend removeAllObjects];
}

#pragma mark NSURLConnection Delegate Methods
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NWDLog(@"Neemware: Error loading inbox data: %@", error.localizedDescription);
    NWDLog(@"Error desc:%@", [error localizedDescription]);
    // Inform the delegate
    if (self.delegate) {
        [self.delegate transferError:self];
    }

}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // Once this method is invoked, "responseData" contains the complete result
    // But we don't really care, just call the delegate to dimiss the view
    // Inform the delegate
    if (self.delegate) {
        [self.delegate transferComplete:self];
    }
}

@end
