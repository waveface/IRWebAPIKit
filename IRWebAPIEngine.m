//
//  IRWebAPIEngine.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/19/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import <objc/runtime.h>
#import "IRWebAPIEngine.h"
#import "IRWebAPIRequestContext.h"
#import "IRWebAPIRequestOperation.h"
#import "IRWebAPIEngineContext.h"

@interface IRWebAPIEngine ()

@property (nonatomic, readwrite, retain) NSMutableArray *globalRequestPreTransformers;
@property (nonatomic, readwrite, retain) NSMutableDictionary *requestTransformers;
@property (nonatomic, readwrite, retain) NSMutableArray *globalRequestPostTransformers;

@property (nonatomic, readwrite, retain) NSMutableArray *globalResponsePreTransformers;
@property (nonatomic, readwrite, retain) NSMutableDictionary *responseTransformers;
@property (nonatomic, readwrite, retain) NSMutableArray *globalResponsePostTransformers;

- (IRWebAPIRequestContext *) requestContextByTransformingContext:(IRWebAPIRequestContext *)inContext forMethodNamed:(NSString *)inMethodName;

- (NSDictionary *) responseByTransformingResponse:(NSDictionary *)inResponse withRequestContext:(IRWebAPIRequestContext *)inRequestContext forMethodNamed:(NSString *)inMethodName;

@end


@implementation IRWebAPIEngine

@synthesize context = _context;
@synthesize queue = _queue;
@synthesize globalRequestPreTransformers = _globalRequestPreTransformers;
@synthesize requestTransformers = _requestTransformers;
@synthesize globalRequestPostTransformers = _globalRequestPostTransformers;
@synthesize globalResponsePreTransformers = _globalResponsePreTransformers;
@synthesize responseTransformers = _responseTransformers;
@synthesize globalResponsePostTransformers = _globalResponsePostTransformers;

- (id) initWithContext:(IRWebAPIEngineContext *)inContext {

	self = [super init];
	if (!self)
		return nil;
	
	_context = inContext;
	
	_queue = [[NSOperationQueue alloc] init];
	_queue.maxConcurrentOperationCount = 8;
	
	_globalRequestPreTransformers = [NSMutableArray array];
	_requestTransformers = [NSMutableDictionary dictionary];
	_globalRequestPostTransformers = [NSMutableArray array];
	
	_globalResponsePreTransformers = [NSMutableArray array];
	_responseTransformers = [NSMutableDictionary dictionary];
	_globalResponsePostTransformers = [NSMutableArray array];
	
	return self;

}

- (id) init {

	return [self initWithContext:nil];

}

- (IRWebAPIRequestOperation *) operationForMethod:(NSString *)method arguments:(NSDictionary *)arguments validator:(IRWebAPIResponseValidator)validator successBlock:(IRWebAPICallback)successBlock failureBlock:(IRWebAPICallback)failureBlock {

	return [self operationForMethod:method arguments:arguments contextOverride:nil validator:validator successBlock:successBlock failureBlock:failureBlock];

}

- (IRWebAPIRequestOperation *) operationForMethod:(NSString *)method arguments:(NSDictionary *)arguments contextOverride:(void(^)(IRWebAPIRequestContext *))overrideBlock validator:(IRWebAPIResponseValidator)validator successBlock:(IRWebAPICallback)successBlock failureBlock:(IRWebAPICallback)failureBlock {

	__weak IRWebAPIEngine *wSelf = self;

	IRWebAPIRequestContext *baseContext = [IRWebAPIRequestContext new];
	baseContext.baseURL = [self.context baseURLForMethodNamed:method];
	baseContext.engineMethod = method;
	
	[arguments enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[baseContext setValue:obj forQueryParam:key];
	}];
	
	if (overrideBlock)
		overrideBlock(baseContext);
	
	IRWebAPIRequestContext *finalizedContext = [self requestContextByTransformingContext:baseContext forMethodNamed:method];
	IRWebAPIRequestOperation *operation = [[IRWebAPIRequestOperation alloc] initWithContext:finalizedContext];
	
	__weak IRWebAPIRequestOperation *wOperation = operation;
	
	[operation setCompletionBlock:^{
	
		IRWebAPIRequestState state = wOperation.state;
		IRWebAPIRequestContext *context = wOperation.context;
		NSDictionary *response = (NSDictionary *)wOperation.result;
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			NSCParameterAssert((state == IRWebAPIRequestStateSucceeded) || (state == IRWebAPIRequestStateFailed));
			
			NSCParameterAssert(!response || [response isKindOfClass:[NSDictionary class]]);

			NSDictionary *transformedResponse = [wSelf responseByTransformingResponse:response withRequestContext:context forMethodNamed:method];
			
			if (state == IRWebAPIRequestStateSucceeded) {
			
				if ((validator != nil) && (!validator(transformedResponse, context))) {

					if (failureBlock)
						failureBlock(transformedResponse, context);
									
				} else {
				
					if (successBlock)
						successBlock(transformedResponse, context);
				
				}
			
			} else {
			
				if (failureBlock)
					failureBlock(transformedResponse, context);

			}
				
		});
	
	}];
	
	return operation;

}

- (NSMutableArray *) requestTransformersForMethodNamed:(NSString *)inMethodName {

	NSMutableArray *returnedArray = [self.requestTransformers objectForKey:inMethodName];
	
	if (!returnedArray) {
	
		returnedArray = [NSMutableArray array];
		[self.requestTransformers setObject:returnedArray forKey:inMethodName];
		
	}
	
	return returnedArray;

}

- (NSMutableArray *) responseTransformersForMethodNamed:(NSString *)inMethodName {

	NSMutableArray *returnedArray = [self.responseTransformers objectForKey:inMethodName];
	
	if (!returnedArray) {
	
		returnedArray = [NSMutableArray array];
		[self.responseTransformers setObject:returnedArray forKey:inMethodName];
		
	}
	
	return returnedArray;

}

- (IRWebAPIRequestContext *) requestContextByTransformingContext:(IRWebAPIRequestContext *)inContext forMethodNamed:(NSString *)inMethodName {

	NSMutableArray *allTransformers = [NSMutableArray array];
	
	[allTransformers addObjectsFromArray:self.globalRequestPreTransformers];
	
	NSArray *methodSpecificTransformers = [self requestTransformersForMethodNamed:inMethodName];
	if (methodSpecificTransformers) {
		[allTransformers addObjectsFromArray:methodSpecificTransformers];
	}
	
	[allTransformers addObjectsFromArray:self.globalRequestPostTransformers];
	
	IRWebAPIRequestContext *currentContext = inContext;
	
	for (IRWebAPIRequestContextTransformer aTransformer in allTransformers)
	currentContext = aTransformer(currentContext);
	
	return currentContext;

}

- (NSDictionary *) responseByTransformingResponse:(NSDictionary *)inResponse withRequestContext:(IRWebAPIRequestContext *)inRequestContext forMethodNamed:(NSString *)inMethodName {

	NSMutableArray *allTransformers = [NSMutableArray array];
	[allTransformers addObjectsFromArray:self.globalResponsePreTransformers];
	[allTransformers addObjectsFromArray:[self responseTransformersForMethodNamed:inMethodName]];
	[allTransformers addObjectsFromArray:self.globalResponsePostTransformers];
	
	NSDictionary *currentResponse = inResponse;
	
	for (IRWebAPIResponseContextTransformer aTransformer in allTransformers)
	currentResponse = aTransformer(currentResponse, inRequestContext);
	
	return currentResponse;

}

@end
