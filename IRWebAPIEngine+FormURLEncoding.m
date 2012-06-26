//
//  IRWebAPIEngine+FormURLEncoding.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "IRWebAPIHelpers.h"
#import "IRWebAPIEngine+FormURLEncoding.h"

extern NSData * IRWebAPIEngineFormURLEncodedDataWithDictionary (NSDictionary *dictionary);

static NSString * const kFormURLEncodingFields = @"-[IRWebAPIRequestContext(FormURLEncoding) formURLEncodingFields]";

@implementation IRWebAPIRequestContext (FormURLEncoding)

- (NSDictionary *) formURLEncodingFields {

	NSMutableDictionary *formURLEncodingFields = objc_getAssociatedObject(self, &kFormURLEncodingFields);
	
	if (!formURLEncodingFields) {
		formURLEncodingFields = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, &kFormURLEncodingFields, formURLEncodingFields, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	
	return [formURLEncodingFields copy];

}

- (void) removeAllFormURLEncodingFieldValues {

	[self willChangeValueForKey:@"formURLEncodingFields"];
	objc_setAssociatedObject(self, &kFormURLEncodingFields, nil, OBJC_ASSOCIATION_ASSIGN);
	[self didChangeValueForKey:@"formURLEncodingFields"];

}

- (void) setValue:(id)obj forFormURLEncodingField:(NSString *)key {

	NSMutableDictionary *formURLEncodingFields = objc_getAssociatedObject(self, &kFormURLEncodingFields);
	
	if (!formURLEncodingFields) {
		formURLEncodingFields = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, &kFormURLEncodingFields, formURLEncodingFields, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	
	[self willChangeValueForKey:@"formURLEncodingFields"];
	
	if (obj) {
		[formURLEncodingFields setObject:obj forKey:key];
	} else {
		[formURLEncodingFields removeObjectForKey:key];
	}
	
	[self didChangeValueForKey:@"formURLEncodingFields"];

}

@end


@implementation IRWebAPIEngine (FormURLEncoding)

+ (IRWebAPIRequestContextTransformer) defaultFormURLEncodingTransformer {

	return [(^ (IRWebAPIRequestContext *context) {
	
		NSDictionary *formURLEncodingFields = context.formURLEncodingFields;
	
		if (![formURLEncodingFields count])
			return context;
		
		[context setValue:@"8bit" forHeaderField:@"Content-Transfer-Encoding"];
		[context setValue:@"application/x-www-form-urlencoded" forHeaderField:@"Content-Type"];
		
		[context setBody:IRWebAPIEngineFormURLEncodedDataWithDictionary(formURLEncodingFields)];
		[context removeAllFormURLEncodingFieldValues];
		
		[context setMethod:@"POST"];
		
		return context;
	
	}) copy];

}

@end


NSData * IRWebAPIEngineFormURLEncodedDataWithDictionary (NSDictionary *formNamesToContents) {

	NSMutableData *sentData = [NSMutableData data];
		
	[formNamesToContents enumerateKeysAndObjectsUsingBlock: ^ (id key, id obj, BOOL *stop) {
	
		if ([sentData length])
			[sentData appendData:[@"&" dataUsingEncoding:NSUTF8StringEncoding]];
		
		[sentData appendData:[IRWebAPIKitRFC3986EncodedStringMake(key) dataUsingEncoding:NSUTF8StringEncoding]];
		[sentData appendData:[@"=" dataUsingEncoding:NSUTF8StringEncoding]];
		[sentData appendData:[IRWebAPIKitRFC3986EncodedStringMake(obj) dataUsingEncoding:NSUTF8StringEncoding]];
		
	}];
	
	return sentData;

}
