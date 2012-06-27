//
//  IRWebAPIRequestContext.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 6/25/12.
//
//

#import <Foundation/Foundation.h>

#import "IRWebAPIKitDefines.h"

@interface IRWebAPIRequestContext : NSObject

@property (nonatomic, readwrite, copy) NSURL *baseURL;
@property (nonatomic, readwrite, copy) NSString *method;
@property (nonatomic, readwrite, copy) NSString *engineMethod;
@property (nonatomic, readwrite, copy) IRWebAPIResponseParser parser;

@property (nonatomic, readwrite, copy) NSData *body;
@property (nonatomic, readwrite, assign) NSTimeInterval timeout;

@property (nonatomic, readonly, copy) NSDictionary *headerFields;
- (void) removeAllHeaderFieldValues;
- (void) setValue:(id)obj forHeaderField:(NSString *)key;

@property (nonatomic, readonly, copy) NSDictionary *queryParams;
- (void) removeAllQueryParamValues;
- (void) setValue:(id)obj forQueryParam:(NSString *)key;

@property (nonatomic, readonly, copy) NSDictionary *userInfo;
- (void) removeAllUserInfoValues;
- (void) setValue:(id)obj forUserInfo:(NSString *)key;

@property (nonatomic, readwrite, strong) NSHTTPURLResponse *urlResponse;
@property (nonatomic, readwrite, strong) NSError *error;

@end
