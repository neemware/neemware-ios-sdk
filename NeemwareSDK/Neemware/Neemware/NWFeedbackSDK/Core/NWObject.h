//
//  NWObject.h
//
//  Created by Puru Choudhary on 12/12/11.
//  Modified by Erik Stromlund on 12/15/2012
//  Copyright (c) 2013 Neemware. All rights reserved.
//
//  This an abstract class that corresponds to a resource on Neemware website.
//

#import <Foundation/Foundation.h>

@interface NWObject : NSObject {
    NSString *_resourcePath;
    NSString *_JSONKey;
}

@property (nonatomic, readonly) NSString *resourcePath;
@property (nonatomic, readonly) NSString *JSONKey;

// Get all the data in dictionary format
- (NSDictionary *)dataInDictionary;

@end
