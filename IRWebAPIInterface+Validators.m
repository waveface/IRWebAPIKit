//
//  IRWebAPIInterface+Validators.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/29/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"


@implementation IRWebAPIInterface (Validators)

+ (IRWebAPIResponseValidator) defaultNoErrorValidator {

	return [(^ (NSDictionary *response, IRWebAPIRequestContext *context) {
	
		return (context.urlResponse.statusCode == 200);
	
	}) copy];

}

@end
