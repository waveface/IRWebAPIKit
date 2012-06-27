//
//  IRWebAPIInterface.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/1/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"

@implementation IRWebAPIInterface

@synthesize engine = _engine, authenticator = _authenticator;

- (id) initWithEngine:(IRWebAPIEngine *)inEngine authenticator:(IRWebAPIAuthenticator *)inAuthenticator {

	self = [super init];
	if (!self)
		return nil;
	
	_engine = inEngine;
	_authenticator = inAuthenticator;
	
	return self;

}

- (id) init {

	return [self initWithEngine:nil authenticator:nil];

}

@end
