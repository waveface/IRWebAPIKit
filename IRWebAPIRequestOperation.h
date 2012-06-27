//
//  IRWebAPIRequestOperation.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 6/25/12.
//
//

#import <Foundation/Foundation.h>

enum {

	IRWebAPIRequestStateEnqueued = 0,
	IRWebAPIRequestStateRunning,
	IRWebAPIRequestStateSucceeded,
	IRWebAPIRequestStateFailed

}; typedef NSUInteger IRWebAPIRequestState;


@class IRWebAPIRequestContext;
@interface IRWebAPIRequestOperation : NSOperation

- (id) initWithContext:(IRWebAPIRequestContext *)context;

@property (nonatomic, readonly, strong) IRWebAPIRequestContext *context;
@property (nonatomic, readonly, assign) IRWebAPIRequestState state;
@property (nonatomic, readonly, strong) NSURLRequest *request;
@property (nonatomic, readonly, strong) NSURLConnection *connection;
@property (nonatomic, readonly, strong) id result;

@end
