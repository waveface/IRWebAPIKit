//
//  IRWebAPIKitDefines.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/23/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IRWebAPIEngine;
@class IRWebAPIEngineContext;
@class IRWebAPIAuthenticator;
@class IRWebAPIInterface;
@class IRWebAPIRequestContext;

typedef NSDictionary * (^IRWebAPIResponseParser) (NSData *inData);
typedef IRWebAPIRequestContext * (^IRWebAPIRequestContextTransformer) (IRWebAPIRequestContext *context);
typedef NSDictionary * (^IRWebAPIResponseContextTransformer) (NSDictionary *inParsedResponse, IRWebAPIRequestContext *inResponseContext);
typedef BOOL (^IRWebAPIResponseValidator) (NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext);
typedef void (^IRWebAPICallback) (NSDictionary *response, IRWebAPIRequestContext *context);
typedef void (^IRWebAPIAuthenticatorCallback) (IRWebAPIAuthenticator *inAuthenticator, BOOL isAuthenticated);
typedef void (^IRWebAPIInterfaceCallback) (NSDictionary *inResponseOrNil);
