//
//  IRWebAPIEngine+FormMultipart.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/23/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPIEngine+FormMultipart.h"


@implementation IRWebAPIEngine (FormMultipart)

+ (IRWebAPIRequestContextTransformer) defaultFormMultipartTransformer {

	return [[(^ (NSDictionary *inOriginalContext) {
	
		NSAssert(NO, @"Implement!");
	
		return inOriginalContext;
	
	}) copy] autorelease];

}

@end
