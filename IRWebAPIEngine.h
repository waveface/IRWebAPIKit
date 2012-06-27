//
//  IRWebAPIEngine.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/19/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IRWebAPIKitDefines.h"

@class IRWebAPIRequestOperation, IRWebAPIEngineContext;

@interface IRWebAPIEngine : NSObject

- (id) initWithContext:(IRWebAPIEngineContext *)inContext;

@property (nonatomic, readonly, strong) IRWebAPIEngineContext *context;
@property (nonatomic, readonly, strong) NSOperationQueue *queue;

@property (nonatomic, readonly, retain) NSMutableArray *globalRequestPreTransformers;
@property (nonatomic, readonly, retain) NSMutableDictionary *requestTransformers;
@property (nonatomic, readonly, retain) NSMutableArray *globalRequestPostTransformers;

@property (nonatomic, readonly, retain) NSMutableArray *globalResponsePreTransformers;
@property (nonatomic, readonly, retain) NSMutableDictionary *responseTransformers;
@property (nonatomic, readonly, retain) NSMutableArray *globalResponsePostTransformers;

- (IRWebAPIRequestOperation *) operationForMethod:(NSString *)method arguments:(NSDictionary *)arguments validator:(IRWebAPIResponseValidator)validator successBlock:(IRWebAPICallback)successBlock failureBlock:(IRWebAPICallback)failureBlock;

- (IRWebAPIRequestOperation *) operationForMethod:(NSString *)method arguments:(NSDictionary *)arguments contextOverride:(void(^)(IRWebAPIRequestContext *))overrideBlock validator:(IRWebAPIResponseValidator)validator successBlock:(IRWebAPICallback)successBlock failureBlock:(IRWebAPICallback)failureBlock;

@end
