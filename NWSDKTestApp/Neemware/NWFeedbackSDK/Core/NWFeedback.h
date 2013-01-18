//
//  NWFeedback.h
//
//  Created by Puru Choudhary on 12/11/11.
//  Modified by Erik Stromlund on 12/15/2012
//  Copyright (c) 2013 Neemware. All rights reserved.
//

#import "NWObject.h"

@interface NWFeedback : NWObject {
    NSNumber               *_rating;        // Required 
    NSString               *_description;   // Optional
    NSString               *_email;         // Optional
}

@property (nonatomic, readonly) NSNumber     *rating;
@property (nonatomic, copy) NSString         *description;
@property (nonatomic, copy) NSString         *email;

- (id)initWithRating:(NSNumber *)rating;

@end
