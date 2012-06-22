//
//  IRWebAPIEngine.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/19/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import <objc/runtime.h>
#import "IRWebAPIEngine.h"





NSString * const kIRWebAPIEngineResponseDictionaryIncomingData = @"kIRWebAPIEngineResponseDictionaryIncomingData";
NSString * const kIRWebAPIEngineResponseDictionaryOutgoingContext = @"kIRWebAPIEngineResponseDictionaryOutgoingContext";

NSString * const kIRWebAPIEngineAssociatedDataStore = @"kIRWebAPIEngineAssociatedDataStore";
NSString * const kIRWebAPIEngineAssociatedResponseContext = @"kIRWebAPIEngineAssociatedResponseContext";
NSString * const kIRWebAPIEngineAssociatedSuccessHandler = @"kIRWebAPIEngineAssociatedSuccessHandler";
NSString * const kIRWebAPIEngineAssociatedFailureHandler = @"kIRWebAPIEngineAssociatedFailureHandler";

NSString * const kIRWebAPIEngineUnderlyingError = @"kIRWebAPIEngineUnderlyingError";





@interface IRWebAPIEngine ()

@property (nonatomic, readwrite, retain) IRWebAPIEngineContext *context;

@property (nonatomic, readwrite, retain) NSMutableArray *globalRequestPreTransformers;
@property (nonatomic, readwrite, retain) NSMutableDictionary *requestTransformers;
@property (nonatomic, readwrite, retain) NSMutableArray *globalRequestPostTransformers;

@property (nonatomic, readwrite, retain) NSMutableArray *globalResponsePreTransformers;
@property (nonatomic, readwrite, retain) NSMutableDictionary *responseTransformers;
@property (nonatomic, readwrite, retain) NSMutableArray *globalResponsePostTransformers;

@property (nonatomic, readwrite, assign) dispatch_queue_t sharedDispatchQueue;


- (void) setInternalDataStore:(NSMutableData *)inDataStore forConnection:(NSURLConnection *)inConnection;
- (NSMutableData *) internalDataStoreForConnection:(NSURLConnection *)inConnection;

- (void) setInternalResponseContext:(NSMutableDictionary *)inResponseContext forConnection:(NSURLConnection *)inConnection;
- (NSMutableDictionary *) internalResponseContextForConnection:(NSURLConnection *)inConnection;

- (void) setInternalSuccessHandler:(void (^)(NSData *inResponse))inSuccessHandler forConnection:(NSURLConnection *)inConnection;
- (void (^)(NSData *inResponse)) internalSuccessHandlerForConnection:(NSURLConnection *)inConnection;

- (void) setInternalFailureHandler:(void (^)(void))inFailureHandler forConnection:(NSURLConnection *)inConnection;
- (void (^)(void)) internalFailureHandlerForConnection:(NSURLConnection *)inConnection;


- (IRWebAPIEngineExecutionBlock) executionBlockForAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil validator:(IRWebAPIResposeValidator)inValidator successHandler:(IRWebAPICallback)inSuccessHandler failureHandler:(IRWebAPICallback)inFailureHandler;

- (void) ensureResponseParserExistence;

- (NSDictionary *) baseRequestContextWithMethodName:(NSString *)inMethodName arguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil;
- (NSDictionary *) requestContextByTransformingContext:(NSDictionary *)inContext forMethodNamed:(NSString *)inMethodName;
- (NSURLRequest *) requestWithContext:(NSDictionary *)inContext;

- (NSDictionary *) parsedResponseForData:(NSData *)inData withContext:(NSDictionary *)inContext;
- (void) handleUnparsableResponseForData:(NSData *)inData context:(NSDictionary *)inContext;

- (NSDictionary *) responseByTransformingResponse:(NSDictionary *)inResponse withRequestContext:(NSDictionary *)inRequestContext forMethodNamed:(NSString *)inMethodName;

- (void) cleanUpForConnection:(NSURLConnection *)inConnection;

@end





@implementation IRWebAPIEngine

@synthesize parser, context;
@synthesize globalRequestPreTransformers, requestTransformers, globalRequestPostTransformers;
@synthesize globalResponsePreTransformers, responseTransformers, globalResponsePostTransformers;
@synthesize sharedDispatchQueue;

# pragma mark -
# pragma mark Initializationand Memory Management

- (id) initWithContext:(IRWebAPIEngineContext *)inContext {

	self = [super init];
	if (!self)
		return nil;
	
	context = inContext;
	
	self.globalRequestPreTransformers = [NSMutableArray array];
	self.requestTransformers = [NSMutableDictionary dictionary];
	self.globalRequestPostTransformers = [NSMutableArray array];

	self.globalResponsePreTransformers = [NSMutableArray array];
	self.responseTransformers = [NSMutableDictionary dictionary];
	self.globalResponsePostTransformers = [NSMutableArray array];
	
	self.sharedDispatchQueue = dispatch_queue_create("com.iridia.WebAPIEngine.queue.main", NULL);

	return self;

}

- (id) init {

	return [self initWithContext:nil];

}

- (void) dealloc {

#if !OS_OBJECT_USE_OBJC
	dispatch_release(sharedDispatchQueue);
#endif

}





# pragma mark -
# pragma mark Helpers

- (void) ensureResponseParserExistence {
	
	if (!self.parser)
		self.parser = IRWebAPIResponseDefaultParserMake();
	
}

- (NSDictionary *) parsedResponseForData:(NSData *)inData withContext:(NSDictionary *)inContext {

	IRWebAPIResponseParser parserBlock = [inContext objectForKey:kIRWebAPIEngineParser];
	
	NSDictionary *parsedResponse = parserBlock(inData);		
	
	if (parsedResponse)
	return parsedResponse;
	
	[self handleUnparsableResponseForData:inData context:inContext];

	return [NSDictionary dictionaryWithObjectsAndKeys:
	
		inData, kIRWebAPIEngineResponseDictionaryIncomingData,
		inContext, kIRWebAPIEngineResponseDictionaryOutgoingContext,
	
	nil];

}

- (void) handleUnparsableResponseForData:(NSData *)inData context:(NSDictionary *)inContext {

	NSLog(@"%@ %s Warning: unparsable response.  Resetting returned response to an empty dictionary.", self, __PRETTY_FUNCTION__);
	
	return;
	
	NSMutableDictionary *displayedContext = [inContext mutableCopy];
	[displayedContext setObject:@"< REMOVED> " forKey:kIRWebAPIEngineRequestHTTPBody];
	
//	This can potentially clog up the wirings
//	IRWebAPIResponseParser defaultParser = IRWebAPIResponseDefaultParserMake();
//	NSDictionary *debugOutput = defaultParser(inData);
//	NSLog(@"Default parser returns %@.", debugOutput ? (id<NSObject>)debugOutput : (id<NSObject>)@"- null -");

}

- (void) fireAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil successHandler:(IRWebAPICallback)inSuccessHandler failureHandler:(IRWebAPICallback)inFailureHandler {

	dispatch_async(self.sharedDispatchQueue, ^ {
	
		dispatch_async(dispatch_get_current_queue(), [self executionBlockForAPIRequestNamed:inMethodName withArguments:inArgumentsOrNil options:nil validator:nil successHandler:inSuccessHandler failureHandler:inFailureHandler]);
	
	});
	
}

- (void) fireAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil validator:(IRWebAPIResposeValidator)inValidator successHandler:(IRWebAPICallback)inSuccessHandler failureHandler:(IRWebAPICallback)inFailureHandler {

	dispatch_async(self.sharedDispatchQueue, ^ {
	
		dispatch_async(dispatch_get_current_queue(), [self executionBlockForAPIRequestNamed:inMethodName withArguments:inArgumentsOrNil options:inOptionsOrNil validator:inValidator successHandler:inSuccessHandler failureHandler:inFailureHandler]);
		
	});

}

- (void) fireAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil successHandler:(IRWebAPICallback)inSuccessHandler failureHandler:(IRWebAPICallback)inFailureHandler {

	dispatch_async(self.sharedDispatchQueue, ^ {
	
		dispatch_async(dispatch_get_current_queue(), [self executionBlockForAPIRequestNamed:inMethodName withArguments:inArgumentsOrNil options:inOptionsOrNil validator:nil successHandler:inSuccessHandler failureHandler:inFailureHandler]);
		
	});
	
}

- (void) enqueueAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil successHandler:(IRWebAPICallback)inSuccessHandler failureHandler:(IRWebAPICallback)inFailureHandler {

	dispatch_async(self.sharedDispatchQueue, ^ {
	
		dispatch_async(self.sharedDispatchQueue, [self executionBlockForAPIRequestNamed:inMethodName withArguments:inArgumentsOrNil options:inOptionsOrNil validator:nil successHandler:inSuccessHandler failureHandler:inFailureHandler]);
		
	});
		
}




	
	
# pragma mark -
# pragma mark Core

- (IRWebAPIEngineExecutionBlock) executionBlockForAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil validator:(IRWebAPIResposeValidator)inValidator successHandler:(IRWebAPICallback)inSuccessHandler failureHandler:(IRWebAPICallback)inFailureHandler {

	__weak IRWebAPIEngine *wSelf = self;

	[self ensureResponseParserExistence];

	void (^retryHandler)(void) = ^ {
	
		[self enqueueAPIRequestNamed:inMethodName withArguments:inArgumentsOrNil options:inOptionsOrNil successHandler:inSuccessHandler failureHandler:inFailureHandler];
	
	};
	
	void (^notifyDelegateHandler)(void) = ^ {
	
		NSLog(@"Notifying delegate of connection finalization");
	
	};
	
	NSDictionary *finalizedContext = [self requestContextByTransformingContext:[self baseRequestContextWithMethodName:inMethodName arguments:inArgumentsOrNil options:inOptionsOrNil] forMethodNamed:inMethodName];

	NSURLRequest *request = [self requestWithContext:finalizedContext];
	
	void (^returnedBlock) (void) = ^ {
			
		dispatch_async(dispatch_get_main_queue(), ^{

			NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
			
			[self setInternalSuccessHandler: ^ (NSData *inResponse) {
			
				BOOL shouldRetry = NO, notifyDelegate = NO;
				
				NSDictionary *responseContext = [wSelf internalResponseContextForConnection:connection];
				NSDictionary *parsedResponse = [wSelf parsedResponseForData:inResponse withContext:finalizedContext];
				NSDictionary *transformedResponse = [wSelf responseByTransformingResponse:parsedResponse withRequestContext:responseContext forMethodNamed:inMethodName];
				
				if ((inValidator != nil) && (!inValidator(transformedResponse, responseContext))) {

					if (inFailureHandler)
					inFailureHandler(transformedResponse, responseContext, &notifyDelegate, &shouldRetry);
									
				} else {
				
					if (inSuccessHandler)
					inSuccessHandler(transformedResponse, responseContext, &notifyDelegate, &shouldRetry);
				
				}
				
				if (shouldRetry) retryHandler();
				if (notifyDelegate) notifyDelegateHandler();
				
				[wSelf cleanUpForConnection:connection];
				
			} forConnection:connection];
			
			
			[self setInternalFailureHandler: ^ {
			
				BOOL shouldRetry = NO, notifyDelegate = NO;
				NSMutableDictionary *responseContext = [wSelf internalResponseContextForConnection:connection];
				NSDictionary *transformedResopnse = [wSelf responseByTransformingResponse:[NSDictionary dictionary] withRequestContext:responseContext forMethodNamed:inMethodName];
				
				if (inFailureHandler)
					inFailureHandler(transformedResopnse, responseContext, &notifyDelegate, &shouldRetry);
				
				if (shouldRetry) retryHandler();
				if (notifyDelegate) notifyDelegateHandler();
				
				[wSelf cleanUpForConnection:connection];
			
			} forConnection:connection];
			
			
			[self setInternalDataStore:[NSMutableData data] forConnection:connection];
			[self setInternalResponseContext:[NSMutableDictionary dictionaryWithObjectsAndKeys:
			
				finalizedContext, kIRWebAPIEngineResponseContextOriginalRequestContext,
			
			nil] forConnection:connection];
			
			[connection start];
		
		});
	
	};
	
	return [returnedBlock copy];

}





# pragma mark -
# pragma mark Connection Delegation

- (void) connection:(NSURLConnection *)inConnection didReceiveData:(NSData *)inData {

	dispatch_async(self.sharedDispatchQueue, ^{

		[[self internalDataStoreForConnection:inConnection] appendData:inData];
	
	});

}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {

	dispatch_async(self.sharedDispatchQueue, ^{

		NSMutableDictionary *responseContext = [self internalResponseContextForConnection:connection];
		[responseContext setObject:response forKey:kIRWebAPIEngineResponseContextURLResponse];
	
	});

}

- (void) connectionDidFinishLoading:(NSURLConnection *)inConnection {

	dispatch_async(self.sharedDispatchQueue, ^{
	
		@try {

			[self internalSuccessHandlerForConnection:inConnection]([self internalDataStoreForConnection:inConnection]);
		
		} @catch (NSException *e) {
		
			[self internalFailureHandlerForConnection:inConnection]();
		
		}
	
	});
	
}

- (void) connection:(NSURLConnection *)inConnection didFailWithError:(NSError *)error {

	dispatch_async(self.sharedDispatchQueue, ^{
	
		[[self internalResponseContextForConnection:inConnection] setObject:error forKey:kIRWebAPIEngineUnderlyingError];
		[self internalFailureHandlerForConnection:inConnection]();
	
	});

}

- (BOOL) connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
	
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
	
}

- (void) connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	
	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
		if ([[self.context.baseURL host] isEqualToString:challenge.protectionSpace.host])
			[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
	
  [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
	
}





# pragma mark -
# pragma mark Associated Objects

//	Notice that blocks are made on the stack so they must be copied before being stored away


- (void) setInternalSuccessHandler:(void (^)(NSData *inResponse))inSuccessHandler forConnection:(NSURLConnection *)inConnection {

	objc_setAssociatedObject(inConnection, CFBridgingRetain(kIRWebAPIEngineAssociatedSuccessHandler), inSuccessHandler, OBJC_ASSOCIATION_COPY);

}

- (void (^)(NSData *inResponse)) internalSuccessHandlerForConnection:(NSURLConnection *)inConnection {

	return objc_getAssociatedObject(inConnection, (__bridge const void *)(kIRWebAPIEngineAssociatedSuccessHandler));

}

- (void) setInternalFailureHandler:(void (^)(void))inFailureHandler forConnection:(NSURLConnection *)inConnection {

	objc_setAssociatedObject(inConnection, CFBridgingRetain(kIRWebAPIEngineAssociatedFailureHandler), inFailureHandler, OBJC_ASSOCIATION_COPY);

}

- (void (^)(void)) internalFailureHandlerForConnection:(NSURLConnection *)inConnection {

	return objc_getAssociatedObject(inConnection, (__bridge const void *)(kIRWebAPIEngineAssociatedFailureHandler));

}

- (void) setInternalDataStore:(NSMutableData *)inDataStore forConnection:(NSURLConnection *)inConnection {

	objc_setAssociatedObject(inConnection, (__bridge const void *)(kIRWebAPIEngineAssociatedDataStore), inDataStore, OBJC_ASSOCIATION_RETAIN);

}

- (NSMutableData *) internalDataStoreForConnection:(NSURLConnection *)inConnection {

	return objc_getAssociatedObject(inConnection, (__bridge const void *)(kIRWebAPIEngineAssociatedDataStore));
	
}

- (void) setInternalResponseContext:(NSMutableDictionary *)inResponseContext forConnection:(NSURLConnection *)inConnection {

	objc_setAssociatedObject(inConnection, (__bridge const void *)(kIRWebAPIEngineAssociatedResponseContext), inResponseContext, OBJC_ASSOCIATION_RETAIN);

}

- (NSMutableDictionary *) internalResponseContextForConnection:(NSURLConnection *)inConnection {

	return objc_getAssociatedObject(inConnection, (__bridge const void *)(kIRWebAPIEngineAssociatedResponseContext));

}

- (void) cleanUpForConnection:(NSURLConnection *)inConnection {

	dispatch_async(dispatch_get_main_queue(), ^{
	
		objc_removeAssociatedObjects(inConnection);
	
	});	

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





- (NSDictionary *) baseRequestContextWithMethodName:(NSString *)inMethodName arguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil {

	NSMutableDictionary *arguments = [NSMutableDictionary dictionary];

	if (inArgumentsOrNil) for (id argumentKey in [inArgumentsOrNil keysOfEntriesPassingTest:^(id key, id object, BOOL *stop) {
	
		if ([object isEqual:@""]) return NO;
		if ([object isEqual:[NSNull null]]) return NO;
		
		return YES;
	
	}]) [arguments setObject:[inArgumentsOrNil objectForKey:argumentKey] forKey:argumentKey];		

	
	NSURL *baseURL = [inOptionsOrNil objectForKey:kIRWebAPIEngineRequestHTTPBaseURL];
	baseURL = baseURL ? baseURL : [self.context baseURLForMethodNamed:inMethodName];
	
	NSMutableDictionary *headerFields = [inOptionsOrNil objectForKey:kIRWebAPIEngineRequestHTTPHeaderFields];
	headerFields = headerFields ? [headerFields mutableCopy] : [NSMutableDictionary dictionary];
	
	id httpBody = [inOptionsOrNil objectForKey:kIRWebAPIEngineRequestHTTPBody];
	httpBody = httpBody ? httpBody : [NSNull null];
	
	NSString *httpMethod = [inOptionsOrNil objectForKey:kIRWebAPIEngineRequestHTTPMethod];
	httpMethod = httpMethod ? [httpMethod copy] : @"GET";
	
	IRWebAPIResponseParser responseParser = [inOptionsOrNil objectForKey:kIRWebAPIEngineParser];
	responseParser = responseParser ? responseParser : self.parser;
	
	NSNumber *timeoutValue = [inOptionsOrNil objectForKey:kIRWebAPIRequestTimeout];
	timeoutValue = timeoutValue ? timeoutValue : [NSNumber numberWithDouble:60.0];
	
	NSMutableDictionary *transformedContext = [NSMutableDictionary dictionaryWithObjectsAndKeys:
	
		baseURL, kIRWebAPIEngineRequestHTTPBaseURL,
		headerFields, kIRWebAPIEngineRequestHTTPHeaderFields,
		arguments, kIRWebAPIEngineRequestHTTPQueryParameters,
		httpBody, kIRWebAPIEngineRequestHTTPBody,
		httpMethod, kIRWebAPIEngineRequestHTTPMethod,
		responseParser, kIRWebAPIEngineParser,
		inMethodName, kIRWebAPIEngineIncomingMethodName,
		timeoutValue, kIRWebAPIRequestTimeout,
	
	nil];
			

	for (id optionValueKey in inOptionsOrNil)
	[transformedContext setValue:[inOptionsOrNil valueForKey:optionValueKey] forKey:optionValueKey];

	return [transformedContext copy];

}

- (NSDictionary *) requestContextByTransformingContext:(NSDictionary *)inContext forMethodNamed:(NSString *)inMethodName {

	NSMutableArray *allTransformers = [NSMutableArray array];
	
	[allTransformers addObjectsFromArray:self.globalRequestPreTransformers];
	
	NSArray *methodSpecificTransformers = [self requestTransformersForMethodNamed:inMethodName];
	
	if (methodSpecificTransformers) {
		[allTransformers addObjectsFromArray:methodSpecificTransformers];
	}
	
	[allTransformers addObjectsFromArray:self.globalRequestPostTransformers];
	
	NSDictionary *currentContext = inContext;
	
	for (IRWebAPIRequestContextTransformer aTransformer in allTransformers)
	currentContext = aTransformer(currentContext);
	
	return currentContext;

}

- (NSDictionary *) responseByTransformingResponse:(NSDictionary *)inResponse withRequestContext:(NSDictionary *)inRequestContext forMethodNamed:(NSString *)inMethodName {

	NSMutableArray *allTransformers = [NSMutableArray array];
	[allTransformers addObjectsFromArray:self.globalResponsePreTransformers];
	[allTransformers addObjectsFromArray:[self responseTransformersForMethodNamed:inMethodName]];
	[allTransformers addObjectsFromArray:self.globalResponsePostTransformers];
	
	NSDictionary *currentResponse = inResponse;
	
	for (IRWebAPIResponseContextTransformer aTransformer in allTransformers)
	currentResponse = aTransformer(currentResponse, inRequestContext);
	
	return currentResponse;

}





- (NSURLRequest *) requestWithContext:(NSDictionary *)inContext {

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:IRWebAPIRequestURLWithQueryParameters(
	
		(NSURL *)[inContext objectForKey:kIRWebAPIEngineRequestHTTPBaseURL],
		[inContext objectForKey:kIRWebAPIEngineRequestHTTPQueryParameters]
	
	) cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:[[inContext objectForKey:kIRWebAPIRequestTimeout] doubleValue]];
	
	[request setHTTPShouldHandleCookies:NO];
	
	NSDictionary *headerFields;
	if ((headerFields = [inContext objectForKey:kIRWebAPIEngineRequestHTTPHeaderFields]))
	for (NSString *headerFieldKey in headerFields)
	[request setValue:[headerFields objectForKey:headerFieldKey] forHTTPHeaderField:headerFieldKey];
	
	NSData *httpBody = [inContext objectForKey:kIRWebAPIEngineRequestHTTPBody];
	if (![httpBody isEqual:[NSNull null]])
	[request setHTTPBody:httpBody];
	
	[request setHTTPMethod:[inContext objectForKey:kIRWebAPIEngineRequestHTTPMethod]];
	
	return [request copy];

}





@end
