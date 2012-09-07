//
//  NWContentData.m
//  NeemwareSDK
//
//  Created by Erik Stromlund (neemware) on 8/7/12.
//  Copyright (c) 2012 Neemware, Inc. All rights reserved.
//

#import "NWContentData.h"

@implementation NWContentData

@synthesize contentID =                 _contentID;
@synthesize contentSubject =            _contentSubject;
@synthesize contentBody =               _contentBody;
@synthesize contentType =               _contentType;
@synthesize contentURL =                _contentURL;
@synthesize contentImageURL =           _contentImageURL;
@synthesize contentRead =               _contentRead;
@synthesize showInBanner =              _showInBanner;
@synthesize cellBackgroundImageURL =    _cellBackgroundImageURL;


- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        [self setContentURL:                [dict   objectForKey:@"content_url"]];
        [self setContentBody:               [dict   objectForKey:@"content_body"]];
        [self setContentID:                 [[dict  objectForKey:@"id"] stringValue]];  // This is a NSNumber otherwise
        [self setContentType:               [dict   objectForKey:@"content_type"]];
        [self setContentRead:               [[dict  objectForKey:@"read"] boolValue]];
        [self setContentSubject:            [dict   objectForKey:@"content_subject"]];
        [self setContentImageURL:           [dict   objectForKey:@"content_image_url"]];
        [self setShowInBanner:              [[dict  objectForKey:@"banner_also"] boolValue]];
        [self setCellBackgroundImageURL:    [dict   objectForKey:@"cell_background_image_url"]];
    }
    return self;
}

-(void)markAsRead
{
    [self setContentRead:YES];
}

@end
