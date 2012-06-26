//
//  IRWebAPIRequestContext.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 6/25/12.
//
//

#import "IRWebAPIRequestContext.h"
#import "IRWebAPIResponseParser.h"

static NSString * const kHeaderFields = @"headerFields";
static NSString * const kQueryParams = @"queryParams";
static NSString * const kUserInfo = @"userInfo";

@implementation IRWebAPIRequestContext {
@package
	NSMutableDictionary *_headerFields;
	NSMutableDictionary *_queryParams;
	NSMutableDictionary *_userInfo;
}

@synthesize baseURL = _baseURL;
@synthesize method = _method;
@synthesize engineMethod = _engineMethod;
@synthesize parser = _parser;
@synthesize body = _body;
@synthesize timeout = _timeout;
@synthesize urlResponse = _urlResponse;
@synthesize error = _error;

- (id) init {

	self = [super init];
	if (!self)
		return nil;
	
	_method = @"GET";
	
	_timeout = 60.0f;
	
	_headerFields = [NSMutableDictionary dictionary];
	_queryParams = [NSMutableDictionary dictionary];
	_userInfo = [NSMutableDictionary dictionary];
	
	_parser = [IRWebAPIResponseDefaultJSONParserMake() copy];
	
	return self;

}

- (void) setBody:(NSData *)body {

	_body = body;

}

- (NSDictionary *) headerFields {

	return [_headerFields copy];

}

- (void) removeAllHeaderFieldValues {

	[self willChangeValueForKey:kHeaderFields];
	[_headerFields removeAllObjects];
	[self didChangeValueForKey:kHeaderFields];

}

- (void) setValue:(id)obj forHeaderField:(NSString *)key {

	[self willChangeValueForKey:kHeaderFields];
	
	if (obj) {
		[_headerFields setObject:obj forKey:key];
	} else {
		[_headerFields removeObjectForKey:key];
	}
	
	[self didChangeValueForKey:kHeaderFields];

}

- (NSDictionary *) queryParams {

	return [_queryParams copy];

}

- (void) removeAllQueryParamValues {

	[self willChangeValueForKey:kQueryParams];
	[_queryParams removeAllObjects];
	[self didChangeValueForKey:kQueryParams];

}

- (void) setValue:(id)obj forQueryParam:(NSString *)key {

	[self willChangeValueForKey:kQueryParams];
	
	if (obj) {
		[_queryParams setObject:obj forKey:key];
	} else {
		[_queryParams removeObjectForKey:key];
	}
	
	[self didChangeValueForKey:kQueryParams];

}

- (NSDictionary *) userInfo {

	return [_userInfo copy];

}

- (void) removeAllUserInfoValues {

	[self willChangeValueForKey:kUserInfo];
	[_userInfo removeAllObjects];
	[self didChangeValueForKey:kUserInfo];

}

- (void) setValue:(id)obj forUserInfo:(NSString *)key {

	[self willChangeValueForKey:kUserInfo];
	
	if (obj) {
		[_userInfo setObject:obj forKey:key];
	} else {
		[_userInfo removeObjectForKey:key];
	}
	
	[self didChangeValueForKey:kUserInfo];

}

@end
