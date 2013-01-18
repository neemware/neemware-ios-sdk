//
//  NWObject.m
//
//  Created by Puru Choudhary on 12/12/11.
//  Modified by Erik Stromlund on 12/15/2012
//  Copyright (c) 2013 Neemware. All rights reserved.
//

#import "NWObject.h"

@implementation NWObject

@synthesize resourcePath = _resourcePath;
@synthesize JSONKey      = _JSONKey;

// Override this in subclass
- (NSDictionary *)dataInDictionary
{
    DLog(@"This method should be subclassed");
    return nil;
}

@end
