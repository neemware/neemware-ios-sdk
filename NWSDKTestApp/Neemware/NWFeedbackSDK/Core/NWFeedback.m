//
//  NWFeedback.m
//
//  Created by Puru Choudhary on 12/11/11.
//  Modified by Erik Stromlund on 12/15/2012
//  Copyright (c) 2013 Neemware. All rights reserved.
//

#import "NWFeedback.h"
#import "Neemware.h"
#import "NWFeedbackConstants.h"

static NSString *kNWFeedbackPath = @"/feedbacks";
static NSString *kNWFeedbackJSONKey = @"feedback";

@implementation NWFeedback

# pragma mark - Accessors
@synthesize rating      = _rating;
@synthesize description = _description;
@synthesize email       = _email;

# pragma mark - Setup and dealloc
- (id)initWithRating:(NSNumber *)rating 
{
    self = [super init];
    if (self) {
        _resourcePath = kNWFeedbackPath;
        _JSONKey      = kNWFeedbackJSONKey;
        _rating       = rating;
    }
    return self;
}

# pragma mark - Misc
- (NSDictionary *)dataInDictionary
{
    DLog(@"begin dataInDictionary method");
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    // Rating
    if (self.rating) {
        [data setObject:self.rating forKey:@"rating"];
    }
    
    // Description
    if (self.description) {
        [data setObject:self.description forKey:@"description"];
    }
    
    // Email
    if (self.email) {
        [data setObject:self.email forKey:@"email"];
    }
    
    // Location
    if ([Neemware location]) {
        NSDictionary *latitude = [NSDictionary dictionaryWithObject:[Neemware latitude] forKey:@"latitude"];
        NSDictionary *longitude = [NSDictionary dictionaryWithObject:[Neemware longitude] forKey:@"longitude"];
        NSMutableDictionary *location = [[NSMutableDictionary alloc] initWithDictionary:latitude];
        [location addEntriesFromDictionary:longitude];
        [data setObject:location forKey:@"location"];
    }
    
    NSDictionary *feedback = [NSDictionary dictionaryWithObject:data forKey:kNWFeedbackJSONKey];
    DLog(@"Feedback dict: %@", feedback);
    return feedback;
}

@end
