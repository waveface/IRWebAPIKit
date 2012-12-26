//
//  IRWebAPIXOAuthAuthenticator.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"
#import "IRWebAPIRequestContext.h"
#import "IRWebAPIXOAuthAuthenticator.h"


@interface IRWebAPIXOAuthAuthenticator ()

@property (nonatomic, retain, readwrite) IRWebAPICredentials *currentCredentials;

- (NSDictionary *) oAuthHeaderValuesForHTTPMethod:(NSString *)inHTTPMethod baseURL:(NSURL *)inBaseURL arguments:(NSDictionary *)inMethodArguments;
- (NSString *) oAuthHeaderValueForHTTPMethod:(NSString *)inHTTPMethod baseURL:(NSURL *)inBaseURL arguments:(NSDictionary *)inMethodArguments;

//	The former returns a dictionary, which is used by the latter, which concatenates everything into a string ready for use in the Authorization header or another header, e.g. X-Verify-Credentials-Authorization


- (NSString *) oAuthHeaderValueForRequestContext:(IRWebAPIRequestContext *)inRequestContext;

//	Convenience.

@end


@implementation IRWebAPIXOAuthAuthenticator

@synthesize consumerKey = _consumerKey;
@synthesize consumerSecret = _consumerSecret;
@synthesize retrievedToken = _retrievedToken;
@synthesize retrievedTokenSecret = _retrievedTokenSecret;
@synthesize currentCredentials = _currentCredentials;

- (void) createTransformerBlocks {

	__weak IRWebAPIXOAuthAuthenticator *wSelf = self;

	self.globalRequestPostTransformerBlock = ^ (IRWebAPIRequestContext *context) {
		
		BOOL isRequestAuthenticated = (BOOL)(!!(self.retrievedTokenSecret)),
			isPOST = [@"POST" isEqual:context.method],
			removesQueryParameters = NO;
		
		if (isRequestAuthenticated && isPOST) {
		
			[context setBody:((^ {

				NSMutableArray *POSTBodyElements = [NSMutableArray array];
				
				[context.queryParams enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
					
					[POSTBodyElements addObject:[NSString stringWithFormat:@"%@=%@", key, IRWebAPIKitRFC3986EncodedStringMake(obj)]];
					
				}];
				
				return [[POSTBodyElements componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding];
			
			})())];
			
			[context setValue:@"application/x-www-form-urlencoded" forHeaderField:@"Content-Type"];
			
			removesQueryParameters = YES;
		
		}
		
		id authHeaderFieldValue = [wSelf oAuthHeaderValueForRequestContext:context];
		
		[context setValue:authHeaderFieldValue forHeaderField:@"Authorization"];
		
		if (removesQueryParameters)
			[context removeAllQueryParamValues];
			
		return context;
	
	};

}

- (void) associateWithEngine:(IRWebAPIEngine *)inEngine {

	[self disassociateEngine];

	self.engine = inEngine;
//	Clear stuff?
	
	[super associateWithEngine:inEngine];

}

- (void) authenticateCredentials:(IRWebAPICredentials *)inCredentials onSuccess:(IRWebAPIAuthenticatorCallback)successHandler onFailure:(IRWebAPIAuthenticatorCallback)failureHandler {
	
	IRWebAPIRequestOperation *operation = [self.engine operationForMethod:@"oauth/access_token" arguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		inCredentials.identifier, @"x_auth_username",
		inCredentials.qualifier, @"x_auth_password",
		@"client_auth", @"x_auth_mode",

	nil] validator: ^ (NSDictionary *response, IRWebAPIRequestContext *context) {
	
		if (!([IRWebAPIInterface defaultNoErrorValidator])(response, context))
		return NO;
	
		for (id key in [NSArray arrayWithObjects:@"oauth_token", @"oauth_token_secret", nil])
			if (!IRWebAPIKitValidResponse([response objectForKey:key]))
				return NO;
		
		return YES;
	
	} successBlock: ^ (NSDictionary *inResponseOrNil, IRWebAPIRequestContext *context) {
		
		self.retrievedToken = [inResponseOrNil valueForKey:@"oauth_token"];
		self.retrievedTokenSecret = [inResponseOrNil valueForKey:@"oauth_token_secret"];

		self.currentCredentials = inCredentials;
		self.currentCredentials.authenticated = YES;

		[self.currentCredentials.userInfo setObject:self.retrievedToken forKey:@"oauth_token"];
		[self.currentCredentials.userInfo setObject:self.retrievedTokenSecret forKey:@"oauth_token_secret"];
		
		NSCParameterAssert(self.currentCredentials && self.currentCredentials.authenticated);

		if (successHandler)
			successHandler(self, YES);
		
	} failureBlock: ^ (NSDictionary *inResponseOrNil, IRWebAPIRequestContext *context) {
	
		self.currentCredentials.authenticated = NO;
		self.retrievedToken = nil;
		self.retrievedTokenSecret = nil;
	
		if (failureHandler)
			failureHandler(self, NO);
	
	}];
	
	operation.context.parser = IRWebAPIResponseQueryResponseParserMake();
	operation.context.method = @"POST";
	
	[operation start];
	
}





- (NSDictionary *) oAuthHeaderValuesForHTTPMethod:(NSString *)inHTTPMethod baseURL:(NSURL *)inBaseURL arguments:(NSDictionary *)inMethodArguments {

	NSMutableDictionary *signatureStringParameters = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *oAuthParameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:

		self.consumerKey, @"oauth_consumer_key",
		IRWebAPIKitNonce(), @"oauth_nonce",
		IRWebAPIKitTimestamp(), @"oauth_timestamp",
		@"HMAC-SHA1", @"oauth_signature_method",
		@"1.0", @"oauth_version",

	nil];
	
	if (self.retrievedToken)
	[oAuthParameters setObject:self.retrievedToken forKey:@"oauth_token"];
	
	
	[signatureStringParameters addEntriesFromDictionary:oAuthParameters];
	
	[inMethodArguments enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
	
		[signatureStringParameters setObject:IRWebAPIKitRFC3986EncodedStringMake(obj) forKey:key];
	
	}];
	
	NSString *signatureBaseString = IRWebAPIKitOAuthSignatureBaseStringMake(
		
		inHTTPMethod, inBaseURL, signatureStringParameters
			
	);
	
	[oAuthParameters setObject:IRWebAPIKitHMACSHA1(
	
		self.consumerSecret, 
		self.retrievedTokenSecret, 
		signatureBaseString
	
	) forKey:@"oauth_signature"];	
	
	return oAuthParameters;
	
}





- (NSString *) oAuthHeaderValueForHTTPMethod:(NSString *)inHTTPMethod baseURL:(NSURL *)inBaseURL arguments:(NSDictionary *)inMethodArguments {
	
	NSDictionary *headerValues = [self oAuthHeaderValuesForHTTPMethod:inHTTPMethod baseURL:inBaseURL arguments:inMethodArguments];
	
	NSMutableArray *contents = [NSMutableArray array];
	
	for (id aKey in headerValues)
	[contents addObject:[NSString stringWithFormat:
	
		@"%@=\"%@\"", 
		aKey, IRWebAPIKitRFC3986EncodedStringMake([headerValues objectForKey:aKey])
	
	]];
	
	return [NSString stringWithFormat:@"OAuth %@", [contents componentsJoinedByString:@", "]];
	
}

- (NSString *) oAuthHeaderValueForRequestContext:(IRWebAPIRequestContext *)context {

	NSString *method = context.method;
	NSURL *baseURL = context.baseURL;
	NSDictionary *arguments = context.queryParams;

	return 	[self oAuthHeaderValueForHTTPMethod:method baseURL:baseURL arguments:arguments];

}

@end
