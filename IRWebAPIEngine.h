//
//  IRWebAPIEngine.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/19/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IRWebAPIKit.h"

extern NSString * const kIRWebAPIEngineResponseDictionaryIncomingData;
extern NSString * const kIRWebAPIEngineResponseDictionaryOutgoingContext;
extern NSString * const kIRWebAPIEngineAssociatedDataStore;
extern NSString * const kIRWebAPIEngineAssociatedResponseContext;
extern NSString * const kIRWebAPIEngineAssociatedSuccessHandler;
extern NSString * const kIRWebAPIEngineAssociatedFailureHandler;
extern NSString * const kIRWebAPIEngineUnderlyingError;


@interface IRWebAPIEngine : NSObject

@property (nonatomic, readwrite, copy) IRWebAPIResponseParser parser;
@property (nonatomic, readonly, retain) IRWebAPIEngineContext *context;

@property (nonatomic, readonly, retain) NSMutableArray *globalRequestPreTransformers;
@property (nonatomic, readonly, retain) NSMutableDictionary *requestTransformers;
@property (nonatomic, readonly, retain) NSMutableArray *globalRequestPostTransformers;

@property (nonatomic, readonly, retain) NSMutableArray *globalResponsePreTransformers;
@property (nonatomic, readonly, retain) NSMutableDictionary *responseTransformers;
@property (nonatomic, readonly, retain) NSMutableArray *globalResponsePostTransformers;

- (id) initWithContext:(IRWebAPIEngineContext *)inContext;

- (void) fireAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil validator:(IRWebAPIResposeValidator)inValidator successHandler:(IRWebAPICallback)inSuccessHandler failureHandler:(IRWebAPICallback)inFailureHandler;

- (NSMutableArray *) requestTransformersForMethodNamed:(NSString *)inMethodName;
- (NSMutableArray *) responseTransformersForMethodNamed:(NSString *)inMethodName;

//	Convenience.  Putting them in a category does not assure compiler checking.

- (void) fireAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil successHandler:(IRWebAPICallback)inSuccessHandler failureHandler:(IRWebAPICallback)inFailureHandler;

- (void) fireAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil successHandler:(IRWebAPICallback)inSuccessHandler failureHandler:(IRWebAPICallback)inFailureHandler;

@end





#import "IRWebAPIEngine+LocalCaching.h"
#import "IRWebAPIEngine+FormMultipart.h"




