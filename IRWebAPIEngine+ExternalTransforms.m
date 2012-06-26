//
//  IRWebAPIEngine+ExternalTransforms.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/14/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPIEngine+ExternalTransforms.h"
#import "IRWebAPIRequestContext.h"
#import "IRWebAPIHelpers.h"

@interface IRWebAPIEngine (ExternalTransforms_KnownPrivate)

- (IRWebAPIRequestContext *) baseRequestContextWithMethodName:(NSString *)inMethodName arguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil;

- (IRWebAPIRequestContext *) requestContextByTransformingContext:(IRWebAPIRequestContext *)inContext forMethodNamed:(NSString *)inMethodName;

- (NSURLRequest *) requestWithContext:(IRWebAPIRequestContext *)inContext;

@end

@implementation IRWebAPIEngine (ExternalTransforms)

- (NSURLRequest *) transformedRequestWithRequest:(NSURLRequest *)aRequest usingMethodName:(NSString *)aName {

	IRWebAPIRequestContext *baseContext = [self baseRequestContextWithMethodName:aName arguments:nil options:nil];
	
	NSURL *baseURL = baseContext.baseURL;
	NSDictionary *headerFields = baseContext.headerFields;
	NSDictionary *arguments = baseContext.queryParams;
	NSData *httpBody = baseContext.body;
	NSString *httpMethod = baseContext.method;
	IRWebAPIResponseParser responseParser = baseContext.parser;
	
	if ([[aRequest allHTTPHeaderFields] count])
		headerFields = [aRequest allHTTPHeaderFields];
		
	if ([aRequest HTTPBody])
		httpBody = [aRequest HTTPBody];
	
	if ([aRequest URL]) {
	
		NSURL *givenURL = [aRequest URL];
		
		NSString *baseURLString = [[NSArray arrayWithObjects:
		
			[givenURL scheme] ? [[givenURL scheme] stringByAppendingString:@"://"]: @"",
			[givenURL host] ? [givenURL host] : @"",
			[givenURL port] ? [@":" stringByAppendingString:[[givenURL port] stringValue]] : @"",
			[givenURL path] ? [givenURL path] : @"",
			//	[givenURL query] ? [@"?" stringByAppendingString:[givenURL query]] : @"",
			//	[givenURL fragment] ? [@"#" stringByAppendingString:[givenURL fragment]] : @"",
		
		nil] componentsJoinedByString:@""];
		
		if ([givenURL query])
			arguments = IRQueryParametersFromString([givenURL query]);
		
		baseURL = [NSURL URLWithString:baseURLString];
	
	}
	
	IRWebAPIRequestContext *inferredContext = [IRWebAPIRequestContext new];
	inferredContext.baseURL = baseURL;
	[headerFields enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[inferredContext setValue:obj forHeaderField:key];
	}];
	[arguments enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[inferredContext setValue:obj forQueryParam:key];
	}];
	inferredContext.body = httpBody;
	inferredContext.method = httpMethod;
	inferredContext.parser = responseParser;
	
	IRWebAPIRequestContext *transformedContext = [self requestContextByTransformingContext:inferredContext forMethodNamed:aName];
	return [[IRWebAPIRequestOperation alloc] initWithContext:transformedContext].request;

}

@end
