//
//  NWContentDataStore.h
//  NeemwareSDK
//
//  Created by Erik Stromlund (neemware) on 8/7/12.
//  Copyright (c) 2012 Neemware, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NWContentData;

@interface NWContentDataStore : NSObject <NSURLConnectionDelegate>
{
    NSMutableArray*     _allContent;
    NSString*           _unreadContentCount;
    NSMutableData*      _responseData;
}

@property (nonatomic, copy)     NSString*       unreadContentCount;
@property (nonatomic, strong)   NSMutableData*  responseData;

+ (NWContentDataStore *)sharedInstance;

// Returns all content
- (NSArray *)allContent;

// Fetches new data from the server
- (void)updateContentData;

// Parses the data from the server and turns it into native objects
- (void)parseInboxData:(NSData *)data;

// Called when the user reads content -- marks both local native object and notifies server
- (void)userReadContent:(NWContentData *)content;

// // Called when the user answers a question content -- server already knows so this deletes the question locally
- (void)userAnsweredQuestion:(NWContentData *)question;

// Returns the next object that is available for display in the banner
- (NWContentData *)nextObjectToDisplayInBanner;
@end
