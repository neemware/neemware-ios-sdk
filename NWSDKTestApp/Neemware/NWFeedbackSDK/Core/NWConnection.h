//
//  NWConnection.h
//
//  Created by Puru Choudhary on 12/12/11.
//  Modified by Erik Stromlund on 12/15/2012
//  Copyright (c) 2013 Neemware. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NWObject;

@class NWConnection;

@protocol NWConnectionDelegate <NSObject>
- (void)transferComplete:(NWConnection *)connection;
- (void)transferError:(NWConnection *)connection;
@end

@interface NWConnection : NSObject <NSURLConnectionDelegate> {
}

@property (nonatomic, assign) id <NWConnectionDelegate> delegate;
@property (nonatomic, strong) NSMutableData *responseData;

- (id)initWithApplicationKey:(NSString *)applicationKey;

// The return value indicates if the object was accepted to be sent
- (BOOL)addObjectToSend:(NWObject *)object;

- (NSArray *)objectsWaitingToBeSent;
- (void)sendObjects;

@end
