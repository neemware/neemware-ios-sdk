//
//  NWContentData.h
//  NeemwareSDK
//
//  Created by Erik Stromlund (Neemware) on 8/7/12.
//  Copyright (c) 2013 Neemware, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NWContentData : NSObject
{
    NSString*   _contentID;
    NSString*   _contentSubject;
    NSString*   _contentBody;
    NSString*   _contentType;
    NSString*   _contentURL;
    NSString*   _contentIconURL;
    NSString*   _cellBackgroundImageURL;
    
    BOOL        _contentRead;
    BOOL        _showInBanner;
}

@property (nonatomic, copy) NSString *contentID;
@property (nonatomic, copy) NSString *contentSubject;
@property (nonatomic, copy) NSString *contentBody;
@property (nonatomic, copy) NSString *contentType;
@property (nonatomic, copy) NSString *contentURL;
@property (nonatomic, copy) NSString *contentIconURL;
@property (nonatomic, copy) NSString *cellBackgroundImageURL;

@property (nonatomic)       BOOL      contentRead;
@property (nonatomic)       BOOL      showInBanner;


// Pass a dictionary containing necessary parameters (those above but lowercase and with _ between words) to create a new object
- (NWContentData *)initWithDictionary:(NSDictionary *)dict;

// Locally marks the content as read
- (void)markAsRead;

@end
