//
//  IRWebAPIInterface+Validators.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/29/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"


@implementation IRWebAPIInterface (Validators)

+ (IRWebAPIResposeValidator) defaultNoErrorValidator {

	return [(^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext) {
	
		NSHTTPURLResponse *response = (NSHTTPURLResponse *)[inResponseContext objectForKey:kIRWebAPIEngineResponseContextURLResponse];
		
		return (response.statusCode == 200);
	
	}) copy];

}

@end
