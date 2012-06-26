//
//  IRWebAPIEngine+OperationFiring.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 6/25/12.
//
//

#import "IRWebAPIEngine+OperationFiring.h"
#import "IRWebAPIRequestContext.h"
#import "IRWebAPIEngine+FormURLEncoding.h"
#import "IRWebAPIRequestOperation.h"
#import "IRWebAPIEngine+FormMultipart.h"

NSString * const kIRWebAPIEngineRequestHTTPBaseURL = @"kIRWebAPIEngineRequestHTTPBaseURL";
NSString * const kIRWebAPIEngineRequestHTTPHeaderFields = @"kIRWebAPIEngineRequestHTTPHeaderFields";
NSString * const kIRWebAPIEngineRequestHTTPPOSTParameters = @"kIRWebAPIEngineRequestHTTPPOSTParameters";
NSString * const kIRWebAPIEngineRequestHTTPBody = @"kIRWebAPIEngineRequestHTTPBody";
NSString * const kIRWebAPIEngineRequestHTTPQueryParameters = @"kIRWebAPIEngineRequestHTTPQueryParameters";
NSString * const kIRWebAPIEngineRequestHTTPMethod = @"kIRWebAPIEngineRequestHTTPMethod";
NSString * const kIRWebAPIEngineParser = @"kIRWebAPIEngineParser";
NSString * const kIRWebAPIEngineResponseContextURLResponse = @"kIRWebAPIEngineResponseContextURLResponse";
NSString * const kIRWebAPIRequestTimeout = @"kIRWebAPIRequestTimeout";

NSString * const kIRWebAPIEngineRequestContextFormURLEncodingFieldsKey = @"kIRWebAPIEngineRequestContextFormURLEncodingFieldsKey";

@implementation IRWebAPIEngine (OperationFiring)

- (void) fireAPIRequestNamed:(NSString *)methodName withArguments:(NSDictionary *)arguments options:(NSDictionary *)options validator:(IRWebAPIResponseValidator)validatorBlock successHandler:(IRWebAPICallback)successBlock failureHandler:(IRWebAPICallback)failureBlock {

	IRWebAPIRequestOperation *operation = [self operationForMethod:methodName arguments:arguments contextOverride:^(IRWebAPIRequestContext *context) {

		if ([options objectForKey:kIRWebAPIEngineRequestHTTPBaseURL])
			context.baseURL = [options objectForKey:kIRWebAPIEngineRequestHTTPBaseURL];
		
		[[options objectForKey:kIRWebAPIEngineRequestHTTPHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[context setValue:obj forHeaderField:key];
		}];
		
		if ([options objectForKey:kIRWebAPIEngineRequestHTTPBody])
			context.body = [options objectForKey:kIRWebAPIEngineRequestHTTPBody];
		
		[[options objectForKey:kIRWebAPIEngineRequestHTTPQueryParameters] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[context setValue:key forQueryParam:key];
		}];
		
		if ([options objectForKey:kIRWebAPIEngineRequestHTTPMethod])
			context.method = [options objectForKey:kIRWebAPIEngineRequestHTTPMethod];
		
		if ([options objectForKey:kIRWebAPIEngineParser])
			context.parser = [options objectForKey:kIRWebAPIEngineParser];
		
		if ([options objectForKey:kIRWebAPIEngineResponseContextURLResponse])
			context.urlResponse = [options objectForKey:kIRWebAPIEngineResponseContextURLResponse];

		if ([options objectForKey:kIRWebAPIRequestTimeout])
			context.timeout = [[options objectForKey:kIRWebAPIRequestTimeout] doubleValue];
		
		[[options objectForKey:kIRWebAPIEngineRequestContextFormURLEncodingFieldsKey] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[context setValue:obj forFormURLEncodingField:key];
		}];
		
	} validator:validatorBlock successBlock:successBlock failureBlock:failureBlock];
		
	[self.queue addOperation:operation];

}

@end
